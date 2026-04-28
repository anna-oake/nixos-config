{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.enable {
    system.defaults = {
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.3;
        # top left hot corner - start screen saver
        wvous-tl-corner = 5;
        # bottom right hot corner - do nothing
        wvous-br-corner = 1;
        persistent-apps = [
          "/Applications/Helium.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/Mail.app"
          "/Applications/Nix Apps/Spotify.app"
          "/Applications/Telegram.app"
          "/Applications/Nix Apps/Element.app"
          "/Applications/Nix Apps/Slack.app"
          "/Applications/Ghostty.app"
          "${pkgs.zed-editor}/Applications/Zed.app"
          "/Applications/Nix Apps/ChatGPT.app"
          "/Applications/Modrinth App.app"
        ];
      };
    };
  };
}
