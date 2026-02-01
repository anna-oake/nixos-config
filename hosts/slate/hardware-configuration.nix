{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.microsoft-surface-common
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  disko.simple = {
    device = "/dev/disk/by-id/nvme-PM991a_NVMe_Samsung_1024GB__S661NE0T403479";
    rootType = "btrfs";
    impermanence.enable = true;
    luks = true;
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  hardware.microsoft-surface.kernelVersion = "stable";

  services.iptsd.enable = lib.mkDefault true;
  environment.systemPackages = [ pkgs.surface-control ];

  boot.secureboot.enable = true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];

  # we need these in initrd to make the keyboard work before luks is decrypted
  boot.initrd.kernelModules = [
    "pinctrl_icelake"
    "intel_lpss"
    "intel_lpss_pci"

    "8250_dw"

    "surface_aggregator"
    "surface_aggregator_registry"
    "surface_aggregator_hub"
    "surface_hid_core"
    "surface_hid"
  ];

  boot.kernelModules = [ "kvm-intel" ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
