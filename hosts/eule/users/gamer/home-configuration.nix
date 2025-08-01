{
  pkgs,
  osConfig,
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    workspace = {
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      lookAndFeel = "org.kde.breezedark.desktop";
    };
    configFile = {
      "kwinrc"."Xwayland"."Scale" = 2;
    };
    session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
  };

  xdg.enable = true;
  xdg.autostart.enable = true;
  xdg.autostart.entries = [
    "${config.home.profileDirectory}/share/applications/steam-minimised.desktop"
  ];

  xdg.desktopEntries."steam-minimised" = {
    name = "Steam (Minimised)";
    exec = "${lib.getExe osConfig.programs.steam.package} -silent";
  };

  xdg.configFile."kwinoutputconfig.json".source = ./files/kwinoutputconfig.json;

  home.stateVersion = "25.11";
}
