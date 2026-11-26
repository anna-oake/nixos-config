{
  config,
  inputs,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ inputs.nixun.nixosModules.redmi-pad-se ];

  nixpkgs.hostPlatform = "aarch64-linux";
  hardware.redmi-pad-se.enable = true;

  boot.initrd.systemd.tpm2.enable = false;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_XUN";
    fsType = "ext4";
    autoResize = true;
  };

  system.build.xunRootImage = pkgs.callPackage "${modulesPath}/../lib/make-disk-image.nix" {
    inherit config pkgs;
    partitionTableType = "none";
    label = "NIXOS_XUN";
    baseName = "userdata";
    copyChannel = false;
  };

  networking.interfaces.usb0.ipv4.addresses = [
    {
      address = "172.16.42.1";
      prefixLength = 24;
    }
  ];
  boot.kernelModules = [ "g_ether" ];

  environment.systemPackages = [ pkgs.qbootctl ];
}
