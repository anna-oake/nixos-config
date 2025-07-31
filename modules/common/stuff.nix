{
  inputs,
  hostName,
  pkgs,
  ...
}:
{
  # common configuration for all architectures
  # please see subdirectories for arch-specific configuration

  imports = [
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
  networking.hostName = hostName;

  system.configurationRevision = inputs.self.rev or "dirty";
}
