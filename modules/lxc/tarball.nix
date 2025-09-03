{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) strings;

  short = strings.removePrefix "lxc-" config.networking.hostName;

  featuresStr = lib.concatStringsSep "," (map (f: "${f}=1") config.lxc.features);

  mountsLines = lib.concatStringsSep "\n" (
    lib.imap0 (i: m: "mp${toString i}: ${m}") config.lxc.mounts
  );

  # i wanna talk a bit about why we add hwaddr=00:00:00:00:00:00 down there.
  #
  # when you restore an LXC backup, you can tick off "unique" and PVE would generate a new one
  # regardless of the value of hwaddr or if hwaddr is even present.
  #
  # however, if you don't tick that off, even if hwaddr is completely missing, PVE won't set a new one!
  # it will generate a random MAC when you start the container, but it will never save it in the config.
  # this leads to a funny situation where if you forget to tick off "unique", the container will have
  # a random MAC address ON EVERY STARTUP.
  #
  # i couldn't find a way to force the "unique" behaviour from within this config file, so instead
  # i'm setting it to 00:00:00:00:00:00 which makes PVE fail to start the container when restored without "unique"
  # forcing the user to go and set a MAC.

  pctConf = pkgs.writeText "pct.conf" ''
    arch: amd64
    cores: ${toString config.lxc.cores}
    features: ${featuresStr}
    hostname: ${short}
    memory: ${toString config.lxc.memory}
    swap: ${toString config.lxc.swap}
    unprivileged: ${if config.lxc.unprivileged then "1" else "0"}
    net0: name=eth0,bridge=${config.lxc.network},hwaddr=00:00:00:00:00:00,ip=dhcp,type=veth
    ostype: unmanaged
    onboot: ${if config.lxc.autoStart then "1" else "0"}
    rootfs: ${config.lxc.storageName}:unknown,size=${toString config.lxc.diskSize}G
    ${mountsLines}
    ${config.lxc.extraConfig}
  '';

  pctFw = pkgs.writeText "pct.fw" ""; # not implemented

  tarball = pkgs.callPackage (pkgs.path + "/nixos/lib/make-system-tarball.nix") {
    fileName = config.image.baseName;
    storeContents = [
      {
        object = config.system.build.toplevel;
        symlink = "none";
      }
    ];

    contents = [
      {
        source = config.system.build.toplevel + "/init";
        target = "/sbin/init";
      }
      {
        source = pctConf;
        target = "/etc/vzdump/pct.conf";
      }
      {
        source = pctFw;
        target = "/etc/vzdump/pct.fw";
      }
    ];

    compressCommand = "zstd -3 -T0 -c";
    compressionExtension = ".zst";
    extraInputs = [ pkgs.zstd ];

    extraArgs = "--transform=s,^etc/vzdump/,./etc/vzdump/,";
  };
in
{
  image.baseName = "vzdump-lxc-${short}-${config.system.configurationRevision}";
  system.build.tarball = lib.mkForce tarball;
}
