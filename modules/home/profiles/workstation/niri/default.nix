{
  osConfig,
  config,
  lib,
  ...
}:
let
  cfg = config.profiles.workstation.niri;
in
{
  options.profiles.workstation.niri = {
    enable = lib.mkEnableOption "niri";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = osConfig.profiles.workstation.niri.enable;
        message = "profiles.workstation.niri.enable must be true in NixOS config as well";
      }
    ];

    programs.niri.settings = {
      prefer-no-csd = true;
    };

    # some bar thing??
    programs.waybar = {
      enable = true;
      settings.mainBar.layer = "top";
      systemd.enable = true;
    };

    # notifications
    services.mako.enable = true;

    # the temu raycast thingie
    programs.fuzzel.enable = true;

    programs.swaylock.enable = true;
  };
}
