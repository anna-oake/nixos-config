{
  config,
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

  hardware.raspberry-pi.configtxt = {
    settings.all.dtparam = lib.mkForce [
      "audio=off"
      "hdmi=off"
    ];

    deviceTreeOverlays.all = lib.mkForce [
      { disable-bt = { }; }
    ];
  };

  boot.initrd.systemd.tpm2.enable = false;

  # The RPi vendor installer writes a versioned image instead of nixpkgs’ expected Image.
  system.boot.loader.kernelFile = "vmlinux-${config.boot.kernelPackages.kernel.modDirVersion}";

  zramSwap.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
