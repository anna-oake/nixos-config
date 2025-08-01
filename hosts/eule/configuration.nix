{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    flake.nixosModules.default
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.useOSProber = true;

  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];

  system.stateVersion = "25.05";
}
