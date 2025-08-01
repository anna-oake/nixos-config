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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];

  system.stateVersion = "25.05";
}
