{
  inputs,
  hostname,
  config,
  ...
}:
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

  # cache
  nix.settings.extra-substituters = [
    "https://attic.oa.ke/nixos"
  ];
  nix.settings.extra-trusted-public-keys = [
    "nixos:qbhh36l2BlhnNhXnU0I2XHOzIT3mzwxKfs86C4am5aY="
  ];
  age.secrets.attic-netrc.file = (inputs.self + /secrets/attic-netrc.age);
  nix.settings.netrc-file = config.age.secrets.attic-netrc.path;

  # overlays
  nixpkgs.overlays = [
    (import (inputs.self + /pkgs))
  ];
}
