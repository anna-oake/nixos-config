{ inputs, hostname, ... }:
{
  # common configuration for all architectures
  # please see subdirectories for arch-specific configuration

  imports = [
    inputs.agenix.nixosModules.default
    ./me.nix
  ];

  # networking
  networking.hostName = hostname;

  # allow unfree pkgs
  nixpkgs.config.allowUnfree = true;

  # flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # overlays
  nixpkgs.overlays = [
    (import (inputs.self + /pkgs))
  ];
}
