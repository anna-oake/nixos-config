{
  config,
  lib,
  pkgs,
  ...
}:
{
  disko.simple = {
    # fucking around disk:
    # device = "/dev/disk/by-id/usb-KIOXIA_EXCERIA_PLUS_635FC19CFPH4-0:0";

    # production disk:
    device = "/dev/disk/by-id/nvme-KINGSTON_SNV3S2000G_50026B73834AB709";
    rootType = "btrfs";
    impermanence.enable = true;
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "ahci"
    "usbhid"
    "uas"
  ];
  boot.kernelModules = [
    "kvm-amd"
  ];

  hardware.firmware = [
    pkgs.rtl8761bu-firmware
  ];

  services.udev.extraRules = ''
    # Allow this Realtek BT dongle to wake the system
    ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="a729", \
      ATTR{power/wakeup}="enabled"
  '';

  networking.interfaces.enp14s0.wakeOnLan.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
