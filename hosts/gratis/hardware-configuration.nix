{
  lib,
  ...
}:
{
  disko.simple.device = "/dev/sda";

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 3;
    };
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_mmio"
    "virtio_blk"
    "virtio_scsi"
    "9p"
    "9pnet_virtio"
    "xhci_pci"
    "virtio_scsi"
  ];

  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
    "virtio_gpu"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
