{
  lib,
  pkgs,
  ...
}:
{
  disko.simple = {
    device = "/dev/vda";
    rootType = "btrfs";
    impermanence.enable = true;
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 1;
    };
    efi.canTouchEfiVariables = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_mmio"
    "virtio_blk"
    "virtio_scsi"
    "9p"
    "9pnet_virtio"
    "xhci_pci"
    "usbhid"
  ];
  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
    "virtio_gpu"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
