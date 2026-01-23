{
  inputs,
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    inputs.steam-rom-manager.homeManagerModules.default
  ];

  programs.steam-rom-manager = {
    enable = true;
    steamUsername = "meowkoteeq";
    environmentVariables = {
      romsDirectory = "/mnt/mynah/family/emudeck/roms";
    };
    emulators = {
      dolphin-emu = {
        enable = true;
        package = pkgs.dolphin-emu;
        romFolder = "wii";
        fileTypes = [
          ".iso"
          ".ISO"
          ".gcm"
          ".GCM"
          ".ciso"
          ".CISO"
        ];
        extraArgs = "--exec=\"\${filePath}\" --batch --confirm=false";
      };
      # disabled because swanstation uses ancient mbedtls
      # duckstation = {
      #   enable = true;
      #   package = pkgs.libretro.swanstation;
      #   extraArgs = "-batch -fullscreen \"\${filePath}\"";
      # };
    };
  };

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

  xdg.configFile."openvr/openvrpaths.vrpath".text =
    let
      steam = "${config.xdg.dataHome}/Steam";
    in
    builtins.toJSON {
      version = 1;
      jsonid = "vrpathreg";

      external_drivers = null;
      config = [ "${steam}/config" ];

      log = [ "${steam}/logs" ];

      runtime = [
        "${pkgs.xrizer}/lib/xrizer"
      ];
    };

  home.stateVersion = "25.11";
}
