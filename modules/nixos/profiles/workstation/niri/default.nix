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

      systemd.user.services.niri-flake-polkit.enable = false;
      services.displayManager.gdm.enable = true;

      programs.niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };

      programs.thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
        ];
      };

      environment.systemPackages = with pkgs; [
        file-roller
        brightnessctl
      ];

      services.gvfs.enable = true;
      services.tumbler.enable = true;
    })
    {
      niri-flake.cache.enable = false;
    }
  ];
}
