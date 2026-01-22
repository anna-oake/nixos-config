{
  lib,
  ...
}:
{
  disko.simple = {
    device = "/dev/sda";
    supportLegacy = true;
  };

  boot.loader.timeout = 0;

  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_mmio"
    "virtio_blk"
    "virtio_scsi"
    "9p"
    "9pnet_virtio"
    "ahci"
    "xhci_pci"
  ];
  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
    "virtio_gpu"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
