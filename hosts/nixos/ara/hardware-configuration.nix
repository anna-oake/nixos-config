{
  lib,
  ...
}:
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [ "usb_storage" ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/0337c57f-cdf1-40b6-a9fd-ff5077ab2fd2";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/1466-1BF0";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
