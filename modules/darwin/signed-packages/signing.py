"""Developer ID signing broker and build client; Python standard library only.

Builders send archives, not filesystem paths. The broker signs its own staging
copy as an ordinary user, then returns it. It never writes into /nix/store.
"""

import argparse
import contextlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import shutil
import socket
import stat
import struct
import subprocess
import sys
import tarfile
import tempfile


MAX_ARCHIVE = 8 * 1024**3
MAX_HEADER = 1024 * 1024
BUNDLE_SUFFIXES = {".app", ".xpc", ".appex", ".bundle", ".framework"}
MACH_MAGICS = {
    b"\xfe\xed\xfa\xce": ">",
    b"\xce\xfa\xed\xfe": "<",
    b"\xfe\xed\xfa\xcf": ">",
    b"\xcf\xfa\xed\xfe": "<",
}
FAT_MAGICS = {
    b"\xca\xfe\xba\xbe": (">", False),
    b"\xbe\xba\xfe\xca": ("<", False),
    b"\xca\xfe\xba\xbf": (">", True),
    b"\xbf\xba\xfe\xca": ("<", True),
}


def normalize_policy(policy):
    if set(policy) - {"entitlements", "removeEntitlements"}:
        raise ValueError("unknown signing policy field")
    return {
        "entitlements": policy.get("entitlements", {}),
        "removeEntitlements": policy.get("removeEntitlements", []),
    }


def write_header(stream, value):
    stream.write(json.dumps(value).encode() + b"\n")
    stream.flush()


def read_header(stream):
    line = stream.readline(MAX_HEADER + 1)
    if len(line) > MAX_HEADER or not line.endswith(b"\n"):
        raise ValueError("invalid signing protocol header")
    value = json.loads(line)
    if not isinstance(value, dict):
        raise ValueError("expected a signing protocol object")
    return value


def copy_exact(source, destination, size):
    if type(size) is not int or not 0 <= size <= MAX_ARCHIVE:
        raise ValueError("signing archive exceeds size limit")
    while size:
        block = source.read(min(size, 1024 * 1024))
        if not block:
            raise ValueError("truncated signing archive")
        destination.write(block)
        size -= len(block)


def tree(root):
    """Walk without following directory symlinks, including dangling links."""
    for directory, dirs, files in os.walk(root, followlinks=False):
        for name in sorted(dirs + files):
            yield Path(directory) / name


def pack(root, archive):
    with tarfile.open(archive, "w", dereference=False) as output:
        for path in tree(root):
            info = output.gettarinfo(str(path), path.relative_to(root).as_posix())
            # Never encode hard links: the receiving side must own its files.
            if info.islnk():
                info.type = tarfile.REGTYPE
                info.linkname = ""
                info.size = path.stat().st_size
            if info.isfile():
                with path.open("rb") as source:
                    output.addfile(info, source)
            elif info.isdir() or info.issym():
                output.addfile(info)
            else:
                raise ValueError(f"unsupported output file: {path}")
    if archive.stat().st_size > MAX_ARCHIVE:
        raise ValueError("signing archive exceeds size limit")


def unpack(archive, root):
    """Extract regular files, directories and links without following links.

    Absolute links are legitimate in Nix outputs. Create all links last and
    reject any archive entry beneath a link, rather than dereferencing them.
    Reject hardlinks, devices, traversal and duplicates.
    """
    root = root.resolve()
    seen = set()
    links = []
    total = 0
    with tarfile.open(archive, "r:") as source:
        for member in source:
            parts = PurePosixPath(member.name).parts
            if not parts or member.name.startswith("/") or ".." in parts:
                raise ValueError("unsafe signing archive path")
            name = PurePosixPath(*parts).as_posix()
            if name in seen:
                raise ValueError("duplicate signing archive path")
            seen.add(name)
            target = root.joinpath(*parts)
            if not (member.isdir() or member.isfile() or member.issym()):
                raise ValueError("unsupported signing archive member")
            # Parents in an existing build output must also never be symlinks.
            parent = root
            for part in parts[:-1]:
                parent /= part
                if parent.is_symlink():
                    raise ValueError("signing archive traverses a symlink")
                parent.mkdir(exist_ok=True)
            if member.issym():
                links.append((target, member.linkname))
                continue
            if target.is_symlink():
                raise ValueError("signing archive overwrites a symlink")
            if member.isdir():
                target.mkdir(exist_ok=True)
                target.chmod((member.mode & 0o777) | 0o700)
            else:
                total += member.size
                if total > MAX_ARCHIVE:
                    raise ValueError("expanded signing archive exceeds size limit")
                # Break possible hard links instead of overwriting their inode.
                if target.exists():
                    target.unlink()
                with source.extractfile(member) as data, target.open("xb") as output:
                    shutil.copyfileobj(data, output)
                target.chmod((member.mode & 0o777) | 0o600)
        for target, link in links:
            relative = target.relative_to(root)
            if any(parent.as_posix() in seen and (root / parent).is_symlink()
                   for parent in relative.parents if parent != Path(".")):
                raise ValueError("signing archive traverses a symlink")
            # Deferred link targets cannot be ancestors of any other entry.
            prefix = relative.as_posix() + "/"
            if any(name.startswith(prefix) for name in seen):
                raise ValueError("signing archive has files beneath a symlink")
            if target.is_symlink() or target.is_file():
                target.unlink()
            elif target.exists():
                raise ValueError("signing archive replaces a directory with a symlink")
            target.symlink_to(link)


def is_macho(path):
    if path.is_symlink() or not path.is_file():
        return False
    with path.open("rb") as source:
        header = source.read(32)
        if len(header) < 16:
            return False
        magic = header[:4]
        if magic in FAT_MAGICS:
            endian, wide = FAT_MAGICS[magic]
            count = struct.unpack(endian + "I", header[4:8])[0]
            if not 1 <= count <= 32:
                return False  # In particular, do not mistake Java classes for Mach-O.
            source.seek(8)
            record = source.read(32 if wide else 20)
            offset = struct.unpack(endian + ("Q" if wide else "I"), record[8:16 if wide else 12])[0]
            source.seek(offset)
            header = source.read(16)
            magic = header[:4]
        return len(header) >= 16 and magic in MACH_MAGICS and struct.unpack(
            MACH_MAGICS[magic] + "I", header[12:16]
        )[0] in {2, 6, 8}  # MH_EXECUTE, MH_DYLIB, MH_BUNDLE, not object files.


def run(argv, *, check=True):
    result = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and result.returncode:
        # Do not include argv: security's unlock password is a command argument.
        raise RuntimeError(f"{Path(argv[0]).name} failed: {result.stderr.decode(errors='replace').strip()}")
    return result


def replace_output(archive, output, directory):
    """Validate the response first, then replace rather than merge its contents.

    In particular, do not retain files deleted by codesign in its staging copy.
    Never chmod or traverse a symlink into another store output.
    """
    received = directory / "received"
    received.mkdir()
    unpack(archive, received)
    output.chmod(output.stat().st_mode | 0o700)
    for path in tree(output):
        if not path.is_symlink() and path.is_dir():
            path.chmod(path.stat().st_mode | 0o700)
    for path in output.iterdir():
        if path.is_symlink() or not path.is_dir():
            path.unlink()
        else:
            shutil.rmtree(path)
    shutil.copytree(received, output, dirs_exist_ok=True, symlinks=True)


def bundle_executable(path):
    for info in (path / "Contents/Info.plist", path / "Resources/Info.plist", path / "Info.plist"):
        if info.is_file():
            with info.open("rb") as source:
                name = plistlib.load(source).get("CFBundleExecutable")
            if name:
                for executable in (path / "Contents/MacOS" / name, path / name):
                    if executable.is_file():
                        return executable
    return None


def ensure_safe_bundle(bundle, root):
    """External resource links can be read, but writable signing paths cannot escape."""
    executable = bundle_executable(bundle)
    if executable is None:
        return False
    if not executable.resolve().is_relative_to(root):
        raise ValueError(f"bundle executable escapes signing staging directory: {bundle}")
    for directory in (bundle, bundle / "Contents", bundle / "Resources"):
        signature = directory / "_CodeSignature"
        if signature.is_symlink() or (signature.exists() and not signature.resolve().is_relative_to(root)):
            raise ValueError("bundle signature directory escapes staging directory")
        if signature.is_dir() and any(path.is_symlink() for path in tree(signature)):
            raise ValueError("bundle signature directory contains symlinks")
    return True


def entitlements_for(path, relative, policy):
    result = run(["/usr/bin/codesign", "--display", "--entitlements", ":-", str(path)], check=False)
    data = result.stdout
    entitlements = {}
    if b"<?xml" in data:
        entitlements = plistlib.loads(data[data.index(b"<?xml"):])
    elif data.startswith(b"bplist"):
        entitlements = plistlib.loads(data)
    for name in policy["removeEntitlements"]:
        entitlements.pop(name, None)
    for name, value in policy["entitlements"].get(relative, {}).items():
        if value is None:
            entitlements.pop(name, None)
        else:
            entitlements[name] = value
    restricted = [name for name in entitlements if name.startswith("com.apple.developer.") or name in {
        "application-identifier", "com.apple.application-identifier", "keychain-access-groups",
        "com.apple.security.application-groups",
    }]
    if restricted:
        raise ValueError(
            f"{relative}: team/profile entitlements require an explicit removal or a separate "
            f"provisioning implementation: {', '.join(sorted(restricted))}"
        )
    return entitlements


def sign_output(root, config, policy):
    root = root.resolve()
    paths = list(tree(root))
    # Do not permit archived links into the signer's home or other mutable paths.
    # Nix store links (for example Zed's bundled git) are left unchanged and never signed.
    for path in paths:
        if path.is_symlink():
            resolved = path.resolve()
            if not resolved.is_relative_to(root) and not resolved.is_relative_to("/nix/store"):
                raise ValueError(f"output symlink escapes staging directory and Nix store: {path}")
    binaries = [path for path in paths if is_macho(path)]
    if not binaries:
        return False
    bundles = []
    for path in paths:
        if path.is_symlink() or not path.is_dir() or path.suffix not in BUNDLE_SUFFIXES:
            continue
        versions = path / "Versions"
        if path.suffix == ".framework" and versions.is_dir():
            bundles.extend(version for version in versions.iterdir()
                           if not version.is_symlink() and version.is_dir()
                           and ensure_safe_bundle(version, root))
        elif ensure_safe_bundle(path, root):
            bundles.append(path)
    # Capture original metadata before signing anything: signing a bundle's main
    # executable changes the entitlements observed when inspecting that bundle.
    targets = sorted(binaries, key=str) + sorted(bundles, key=lambda path: (-len(path.parts), str(path)))
    metadata = []
    for path in targets:
        relative = path.relative_to(root).as_posix()
        details = run(["/usr/bin/codesign", "--display", "--verbose=4", str(path)], check=False)
        metadata.append((path, relative, entitlements_for(path, relative, policy),
                         re.search(rb"flags=0x[0-9a-fA-F]+\([^\n)]*\bruntime\b", details.stderr) is not None))
    known = {relative for _, relative, _, _ in metadata}
    if set(policy["entitlements"]) - known:
        raise ValueError("entitlement policy refers to code paths absent from this output")
    password_path = Path(config["passwordFile"])
    permissions = password_path.stat()
    if password_path.is_symlink() or permissions.st_uid != os.geteuid() or permissions.st_mode & 0o077:
        raise ValueError("keychain password file must be owned by the service user with mode 0600")
    password = password_path.read_text().rstrip("\r\n")
    run(["/usr/bin/security", "unlock-keychain", "-p", password, config["keychain"]])
    with tempfile.TemporaryDirectory(prefix="entitlements-") as directory:
        entitlement_file = Path(directory) / "entitlements.plist"
        for path, relative, entitlements, runtime in metadata:
            entitlement_file.write_bytes(plistlib.dumps(entitlements))
            argv = ["/usr/bin/codesign", "--force", "--sign", config["identity"],
                    "--keychain", config["keychain"], "--timestamp",
                    "--preserve-metadata=identifier", "--entitlements", str(entitlement_file)]
            if runtime:
                argv += ["--options", "runtime"]
            run(argv + [str(path)])
            details = run(["/usr/bin/codesign", "--display", "--verbose=4", str(path)])
            if f"TeamIdentifier={config['teamId']}" not in details.stderr.decode():
                raise ValueError(f"unexpected signing team for {relative}")
        for path in targets:
            run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(path)])
    return True


def handle(stream, config):
    request = read_header(stream)
    name = request.get("package")
    configured_policy = config["packages"].get(name)
    if configured_policy is None:
        raise ValueError("package is not enabled on this signing host")
    policy = normalize_policy(request.get("policy", {}))
    if (request.get("identity") != config["identity"] or request.get("teamId") != config["teamId"]
            or policy != normalize_policy(configured_policy)):
        raise ValueError("build and signing host identity/policy differ; update the signing host")
    with tempfile.TemporaryDirectory(prefix="nix-developer-id-") as directory:
        staging = Path(directory)
        archive = staging / "input.tar"
        with archive.open("wb") as destination:
            copy_exact(stream, destination, request.get("size"))
        root = staging / "output"
        root.mkdir()
        unpack(archive, root)
        changed = sign_output(root, config, policy)
        archive.unlink()
        if not changed:
            write_header(stream, {"ok": True, "size": 0})
            return
        archive = staging / "signed.tar"
        pack(root, archive)
        write_header(stream, {"ok": True, "size": archive.stat().st_size})
        with archive.open("rb") as source:
            shutil.copyfileobj(source, stream)
        stream.flush()
        print(f"signed {name}", flush=True)


def serve(config):
    os.umask(0o077)
    socket_path = Path(config["socketPath"])
    # launchd serializes instances. Never delete another live service's socket.
    if socket_path.exists():
        with socket.socket(socket.AF_UNIX) as probe:
            try:
                probe.connect(str(socket_path))
            except ConnectionRefusedError:
                socket_path.unlink()
            else:
                raise RuntimeError("signing service is already listening")
    with socket.socket(socket.AF_UNIX) as server:
        server.bind(str(socket_path))
        socket_path.chmod(0o660)
        server.listen(16)
        print(f"Developer ID signer listening on {socket_path}", flush=True)
        while True:
            connection, _ = server.accept()
            with connection:
                connection.settimeout(3600)
                with connection.makefile("rwb") as stream:
                    try:
                        handle(stream, config)
                    except Exception as error:
                        print(f"signing failed: {error}", file=sys.stderr, flush=True)
                        with contextlib.suppress(OSError):
                            write_header(stream, {"ok": False, "error": str(error)})


def client(args):
    output = Path(args.output)
    # Skip non-code outputs without depending on a running signing service.
    if not any(is_macho(path) for path in tree(output)):
        return
    request = json.loads(Path(args.request).read_text())
    with tempfile.TemporaryDirectory(prefix="developer-id-client-") as directory:
        archive = Path(directory) / "output.tar"
        pack(output, archive)
        request["size"] = archive.stat().st_size
        with socket.socket(socket.AF_UNIX) as connection:
            connection.settimeout(3600)
            try:
                connection.connect(args.socket)
            except OSError as error:
                raise RuntimeError(
                    "Developer ID signing service is unavailable. Bootstrap the service and "
                    "dedicated keychain on this builder before building signed packages."
                ) from error
            with connection.makefile("rwb") as stream:
                write_header(stream, request)
                with archive.open("rb") as source:
                    shutil.copyfileobj(source, stream)
                stream.flush()
                response = read_header(stream)
                if not response.get("ok"):
                    raise RuntimeError(response.get("error", "signing failed"))
                size = response.get("size")
                if size == 0:
                    return
                with archive.open("wb") as destination:
                    copy_exact(stream, destination, size)
        replace_output(archive, output, Path(directory))
        print(f"Developer ID signed {output}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    server = commands.add_parser("serve")
    server.add_argument("--config", required=True)
    build = commands.add_parser("client")
    build.add_argument("--socket", required=True)
    build.add_argument("--request", required=True)
    build.add_argument("--output", required=True)
    args = parser.parse_args()
    if args.command == "serve":
        serve(json.loads(Path(args.config).read_text()))
    else:
        client(args)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        sys.exit(str(error))
