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

    environment.etc."xdg/autostart/1password.desktop" =
      lib.mkIf config.programs._1password-gui.autoStart
        {
          source = lib.mkForce (
            pkgs.runCommand "1password-autostart.desktop" { } ''
              sed 's|^Exec=1password|Exec=1password --silent|' \
                ${config.programs._1password-gui.package}/share/applications/1password.desktop > $out
            ''
          );
        };

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
