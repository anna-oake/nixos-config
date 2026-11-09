{
  inputs,
  lib,
  pkgs,
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

  # TODO: watch nixos-hardware fix this
  boot.kernelPackages = pkgs.linuxPackagesFor (
    (pkgs.callPackage "${inputs.nixos-hardware}/raspberry-pi/common/kernel.nix" {
      rpiVersion = 5;
    }).overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ pkgs.kernelPatches.tools_128bit_types.patch ];
      })
  );

  zramSwap.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
