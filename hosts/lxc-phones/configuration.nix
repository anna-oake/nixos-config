{
  config,
  inputs,
  lib,
  ...
}:
let
  common = import ./common.nix;

  phone = extra: lib.recursiveUpdate common extra;

  devices =
    lib.mapAttrs'
      (file: type: {
        name = lib.removeSuffix ".nix" file;
        value = phone (import (./phones + "/${file}"));
      })
      (
        lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".nix" file) (
          builtins.readDir ./phones
        )
      );
in
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.enable = true;

  age.secrets."cisco-secrets" = { };

  services.cisco = {
    enable = true;

    secretsPath = config.age.secrets."cisco-secrets".path;

    ringtones = {
      "Penis" = ./ringtones/penis.raw;
    };

    inherit devices;
  };

  lxc.enable = true;

  system.stateVersion = "25.11";
}
