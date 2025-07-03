{
  inputs,
  config,
  pkgs,
  ...
}:
let
  unstable = import inputs.nix-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  # allow unfree pkgs
  nixpkgs.config.allowUnfree = true;

  # flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # add "unstable" to modules args
  _module.args.unstable = unstable;

  # auto gc
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

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
    inputs.nix-vscode-extensions.overlays.default
    inputs.agenix.overlays.default
    (import (inputs.self + /pkgs))
  ];
}
