{
  inputs,
  config,
  lib,
  ...
}:
{
  # cache
  nix.settings = lib.optionalAttrs config.age.ready {
    extra-substituters = [
      "https://attic.oa.ke/nixos"
    ];
    extra-trusted-public-keys = [
      "nixos:qbhh36l2BlhnNhXnU0I2XHOzIT3mzwxKfs86C4am5aY="
    ];
    netrc-file = config.age.secrets.attic-netrc.path;
  };
  age.secrets = lib.mkIf config.age.ready {
    attic-netrc.rekeyFile = (inputs.self + /secrets/secrets/attic-netrc.age);
  };

  # overlays
  nixpkgs.overlays = [
    inputs.nix-vscode-extensions.overlays.default
  ];
}
