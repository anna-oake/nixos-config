{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
  ];

  disko.simple = {
    device = "/dev/mmcblk0";
    rootType = "btrfs";
    impermanence.enable = true;
  };

  hardware.raspberry-pi.firmware = {
    enable = true;
    path = "/boot";
    uboot.enable = true;
  };

  boot.initrd.systemd.tpm2.enable = false;

  zramSwap.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
