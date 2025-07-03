{
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
  ];

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "usbhid"
    "sdhci_acpi"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/5abcae7e-9629-4ddd-ac7f-a4827954c58a";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5C01-1F42";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
