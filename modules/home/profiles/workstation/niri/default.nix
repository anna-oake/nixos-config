{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.workstation.niri;
in
{
  imports = [
    ./shell.nix
    ./theme
  ];

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

    home.packages = with pkgs; [
      sway-contrib.grimshot
    ];

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    gtk = {
      enable = true;

      gtk3.bookmarks = [
        "file:///${config.xdg.userDirs.documents}"
        "file:///${config.xdg.userDirs.pictures}"
        "file:///${config.xdg.userDirs.videos}"
        "file:///${config.xdg.userDirs.download}"
      ];
    };

    programs.niri.package = osConfig.programs.niri.package;

    programs.niri.settings = {
      prefer-no-csd = true;

      cursor = {
        theme = config.stylix.cursor.name;
        inherit (config.stylix.cursor) size;
      };

      outputs = {
        "eDP-1" = {
          scale = 1.5;
        };
      };

      overview = {
        workspace-shadow.enable = false;
      };

      binds = with config.lib.niri.actions; {
        "Mod+Q".action = spawn "ghostty";
        "Mod+X".action = spawn "signalis-ctl" "launcher" "toggle";
        "Mod+L".action = spawn "signalis-ctl" "lock";
        "Mod+E".action = spawn "thunar";

        XF86AudioRaiseVolume = {
          allow-when-locked = true;
          action = spawn "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "5%+";
        };
        XF86AudioLowerVolume = {
          allow-when-locked = true;
          action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
        };
        XF86AudioMute = {
          allow-when-locked = true;
          action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
        };
        XF86AudioMicMute = {
          allow-when-locked = true;
          action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
        };
        XF86MonBrightnessUp = {
          allow-when-locked = true;
          action = spawn "signalis-ctl" "brightness" "up";
        };
        XF86MonBrightnessDown = {
          allow-when-locked = true;
          action = spawn "signalis-ctl" "brightness" "down";
        };

        "Mod+C" = {
          action = close-window;
          repeat = false;
        };

        "Mod+W".action = focus-window-or-workspace-up;
        "Mod+A".action = focus-column-left;
        "Mod+S".action = focus-window-or-workspace-down;
        "Mod+D".action = focus-column-right;

        "Mod+Ctrl+W".action = move-column-to-workspace-up;
        "Mod+Ctrl+A".action = move-column-left;
        "Mod+Ctrl+S".action = move-column-to-workspace-down;
        "Mod+Ctrl+D".action = move-column-right;

        "Mod+Alt+W".action = focus-monitor-up;
        "Mod+Alt+A".action = focus-monitor-left;
        "Mod+Alt+S".action = focus-monitor-down;
        "Mod+Alt+D".action = focus-monitor-right;

        "Mod+Alt+Ctrl+W".action = move-column-to-monitor-up;
        "Mod+Alt+Ctrl+A".action = move-column-to-monitor-left;
        "Mod+Alt+Ctrl+S".action = move-column-to-monitor-down;
        "Mod+Alt+Ctrl+D".action = move-column-to-monitor-right;

        "Mod+grave".action = toggle-overview;
        "Mod+G".action = consume-or-expel-window-left;
        "Mod+H".action = consume-or-expel-window-right;

        "Mod+Shift+G".action = consume-window-into-column;
        "Mod+Shift+H".action = expel-window-from-column;

        "Mod+R".action = switch-preset-column-width;
        "Mod+Shift+R".action = switch-preset-window-height;
        "Mod+Ctrl+R".action = reset-window-height;

        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;
        "Mod+Ctrl+F".action = expand-column-to-available-width;

        "Mod+Shift+Minus".action = set-window-height "-10%";
        "Mod+Shift+Equal".action = set-window-height "+10%";

        "Mod+V".action = toggle-window-floating;
        "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

        "Print".action = spawn "grimshot" "--notify" "savecopy" "output";
        "Mod+Shift+S".action = spawn "grimshot" "--notify" "savecopy" "area";

        "Mod+Escape" = {
          allow-inhibiting = false;
          action = toggle-keyboard-shortcuts-inhibit;
        };

        "Ctrl+Alt+Delete".action = quit;
      };

      input = {
        keyboard = {
          xkb = {
            layout = "us,ru";
            options = "grp:win_space_toggle";
          };
        };

        touchpad = {
          tap = true;
          click-method = "clickfinger";
          natural-scroll = true;
        };

        mouse = {
          accel-profile = "flat";
        };
      };

      layout = {
        gaps = 4;

        center-focused-column = "never";
        background-color = "transparent";

        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];

        default-column-width = {
          proportion = 0.5;
        };

      };
    };
  };
}
