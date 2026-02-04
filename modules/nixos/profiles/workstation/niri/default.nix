{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.profiles.workstation.niri;
in
{
  imports = [
    inputs.niri.nixosModules.niri
  ];

  options.profiles.workstation.niri = {
    enable = lib.mkEnableOption "Niri workstation profile";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      profiles.workstation.enable = lib.mkForce true;

      nixpkgs.overlays = [ inputs.niri.overlays.niri ];

      programs.niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };
    })
    {
      niri-flake.cache.enable = false;
    }
  ];
}
