{
  lib,
  ...
}:
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "usb_storage"
    "sdhci_pci"
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/0c0525cb-6dda-41f4-9208-21c3bbaa8656";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/3242-1D16";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
