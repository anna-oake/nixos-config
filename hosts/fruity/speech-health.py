"""Probe Wyoming, recovering after five consecutive failed minute checks."""

import json
from pathlib import Path
import socket
import subprocess


STATE = Path("/var/run/speech-server-health-failures")


def probe(host="127.0.0.1", port=10300):
    with socket.create_connection((host, port), timeout=10) as connection:
        connection.settimeout(10)
        connection.sendall(b'{"type":"describe","version":"1.0.0"}\n')
        with connection.makefile("rb") as stream:
            header = json.loads(stream.readline(4096))
            length = header.get("data_length", 0)
            if header.get("type") != "info" or not 0 < length <= 1024 * 1024:
                raise ValueError("Invalid Wyoming info header")
            body = stream.read(length)
            if len(body) != length:
                raise ValueError("Truncated Wyoming info response")
            info = json.loads(body)
            if not info.get("asr") or not info.get("tts"):
                raise ValueError("Wyoming speech capabilities missing")


def main():
    try:
        probe()
    except (OSError, ValueError) as error:
        try:
            failures = int(STATE.read_text()) + 1
        except (FileNotFoundError, ValueError):
            failures = 1
        STATE.write_text(str(failures))
        print(f"Wyoming health check failed ({failures}/5): {error}", flush=True)
        # Allow model initialization and transient failures several minutes.
        if failures >= 5:
            print("Restarting org.nixos.speech-server", flush=True)
            subprocess.run(
                ["/bin/launchctl", "kickstart", "-k", "system/org.nixos.speech-server"],
                check=True,
            )
            STATE.unlink(missing_ok=True)
    else:
        STATE.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
