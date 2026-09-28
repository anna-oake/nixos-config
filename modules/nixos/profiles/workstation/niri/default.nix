{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.profiles.workstation.niri;
  shell = pkgs.signalis-shell;
in
{
  imports = [
    inputs.stylix.nixosModules.stylix
    ./greeter.nix
  ];

  options.profiles.workstation.niri = {
    enable = lib.mkEnableOption "Niri workstation profile";
  };

  config = lib.mkIf cfg.enable {
    profiles.workstation.enable = lib.mkForce true;

    nixpkgs.overlays = [ inputs.niri.overlays.niri ];

    programs.niri = {
      enable = true;
      package = pkgs.niri-stable;
      useNautilus = false;
    };

    xdg.portal.xdgOpenUsePortal = true;

    # battery readout in the shell bar
    services.upower.enable = true;

    environment.systemPackages = with pkgs; [
      file-roller
      brightnessctl
      xwayland-satellite-stable
      shell
    ];

    fonts.packages = map (font: font.package) (lib.attrValues shell.fonts);

    security.pam.services.signalis-lock.fprintAuth = false;

    stylix = {
      enable = true;
      polarity = "dark";
      base16Scheme = shell.palette.base16 // {
        scheme = "Signalis";
        author = "Anna Oake";
      };
      fonts = {
        sansSerif = {
          package = pkgs.adwaita-fonts;
          name = "Adwaita Sans";
        };
        serif = config.stylix.fonts.sansSerif;
        monospace = {
          package = pkgs.comic-code-font;
          name = "Comic Code";
        };
        sizes = {
          applications = 11;
          desktop = 11;
          popups = 11;
          terminal = 12;
        };
      };
      cursor = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = 24;
      };
      targets.plymouth.enable = false;
      targets.chromium.enable = false;
      icons = {
        enable = true;
        package = pkgs.papirus-icon-theme;
        dark = "Papirus-Dark";
        light = "Papirus-Light";
      };
    };

    programs._1password-gui.autostart.silent = true;

    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
      ];
    };

    services.gvfs.enable = true;
    services.tumbler.enable = true;
  };
}
