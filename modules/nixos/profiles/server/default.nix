{
  config,
  lib,
  ...
}:
{
  imports = [
    ./user.nix
  ];

  config = lib.mkIf config.profiles.server.enable {
    lxc.pve.host = lib.mkDefault ("mynah." + config.me.lanDomain);

    # mynah host driver
    lxc.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.71.05";
      sha256_64bit = "sha256-NiA7iWC35JyKQva6H1hjzeNKBek9KyS3mK8G3YRva4I=";
      openSha256 = "sha256-Lfz71QWKM6x/jD2B22SWpUi7/og30HRlXg1kL3EWzEw=";
      useSettings = false;
      usePersistenced = false;
    };

    monitoring.logs = {
      systemd.enable = lib.mkDefault true;
      docker.enable = lib.mkDefault config.virtualisation.docker.enable;
    };
  };
}
