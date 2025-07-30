{
  inputs,
  hostname,
  pkgs,
  ...
}:
{
  # common configuration for all architectures
  # please see subdirectories for arch-specific configuration

  imports = [
    ./me.nix
    ./nix.nix
    ./agenix.nix
    inputs.nix-things.commonModules.default
  ];

  environment.systemPackages = with pkgs; [
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
