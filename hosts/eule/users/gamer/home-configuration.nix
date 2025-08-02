{
  pkgs,
  osConfig,
  inputs,
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
  };

  xdg.enable = true;
  xdg.autostart.enable = true;
  xdg.autostart.entries = [
    "${osConfig.programs.steam.package}/share/applications/steam.desktop"
  ];
  xdg.configFile."kwinoutputconfig.json".source = ./files/kwinoutputconfig.json;

  home.stateVersion = "25.11";
}
