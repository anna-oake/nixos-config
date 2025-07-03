{
  inputs,
  hostname,
  pkgs,
  lib,
  ...
}:
{
  # common configuration for all architectures
  # please see subdirectories for arch-specific configuration

  imports = [
    ./me.nix
    ./nix.nix
    inputs.agenix.nixosModules.default
  ];

  environment.systemPackages = with pkgs; [
    agenix
    gh
    git
    htop
    btop
    nixfmt-rfc-style
    nixd
    fzf
    zoxide
  ];

  # networking
  networking.hostName = hostname;

  system.configurationRevision = inputs.self.rev or "dirty";
}
