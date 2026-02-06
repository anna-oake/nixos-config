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
  disabledModules = [ "programs/wayland/niri.nix" ];

  options.profiles.workstation.niri = {
    enable = lib.mkEnableOption "Niri workstation profile";
  };

  config = lib.mkIf cfg.enable (
    let
      package = pkgs.niri-unstable;
    in
    {
      profiles.workstation.enable = lib.mkForce true;

      nixpkgs.overlays = [ inputs.niri.overlays.niri ];

      environment.systemPackages = with pkgs; [
        package
        xdg-utils
        file-roller
        brightnessctl
      ];
      xdg = {
        autostart.enable = true;
        menus.enable = true;
        mime.enable = true;
        icons.enable = true;
      };

      services.displayManager.sessionPackages = [ package ];
      hardware.graphics.enable = true;

      xdg.portal = {
        enable = true;
        configPackages = [ package ];
      };

      security.polkit.enable = true;
      services.gnome.gnome-keyring.enable = true;

      security.pam.services.swaylock = { };
      programs.dconf.enable = true;
      fonts.enableDefaultPackages = true;

      services.displayManager.gdm.enable = true;

      programs.thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
        ];
      };

      services.gvfs.enable = true;
      services.tumbler.enable = true;
    }
  );
}
