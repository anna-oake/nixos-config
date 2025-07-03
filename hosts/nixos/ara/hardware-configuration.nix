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
      device = "/dev/nvme0n1p5";
      fsType = "btrfs";
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
