{
  pkgs,
  inputs,
  system,
  lib,
  ...
}:
{
  # common configuration for x86_64 Linux machines

  imports = [
    ./localisation.nix
    ./network.nix
    ./user.nix
    ./secureboot.nix
    # inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # boot
  boot.loader.timeout = 0;

  # user
  users.user = lib.mkDefault true;

  # pkgs
  services.fwupd.enable = true;
  environment.systemPackages = with pkgs; [
    git
  ];
}
