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

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config = {
        common = {
          default = [
            "gtk"
            "gnome"
          ];
        };
        niri = {
          default = [
            "gtk"
            "gnome"
          ];
        };
      };
    };

    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];

    services.polkit-gnome.enable = true;

    dconf = {
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    gtk = {
      enable = true;

      iconTheme = {
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
      };

      gtk3.bookmarks = [
        "file:///${config.xdg.userDirs.documents}"
        "file:///${config.xdg.userDirs.pictures}"
        "file:///${config.xdg.userDirs.videos}"
        "file:///${config.xdg.userDirs.download}"
      ];
    };

    programs.niri.package = pkgs.niri-unstable;

    programs.niri.settings = {
      prefer-no-csd = true;

      outputs = {
        "eDP-1" = {
          scale = 1.6;
        };
      };

      overview = {
        workspace-shadow.enable = false;
      };

      # window-rules = [
      #   {
      #     geometry-corner-radius = {
      #       bottom-left = 15.0;
      #       bottom-right = 15.0;
      #       top-left = 15.0;
      #       top-right = 15.0;
      #     };
      #     clip-to-geometry = true;
      #   }
      # ];

      binds = with config.lib.niri.actions; {
        "Mod+Q".action = spawn "ghostty";
        "Mod+X".action = spawn "fuzzel";
        "Mod+L".action = spawn "swaylock-plugin";
        "Mod+E".action = spawn "thunar";

        # XF86AudioRaiseVolume = {
        #   allow-when-locked = true;
        #   action = spawn "ignisctl-rs" "run-command" "volume-osd-increase";
        # };
        # XF86AudioLowerVolume = {
        #   allow-when-locked = true;
        #   action = spawn "ignisctl-rs" "run-command" "volume-osd-decrease";
        # };
        # XF86AudioMute = {
        #   allow-when-locked = true;
        #   action = spawn "ignisctl-rs" "run-command" "volume-osd-toggle-mute";
        # };

        # XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

        # // Example brightness key mappings for brightnessctl.
        # // You can use regular spawn with multiple arguments too (to avoid going through "sh"),
        # // but you need to manually put each argument in separate "" quotes.
        XF86MonBrightnessUp = {
          allow-when-locked = true;
          action = spawn "brightnessctl" "--class=backlight" "set" "+10%";
        };
        XF86MonBrightnessDown = {
          allow-when-locked = true;
          action = spawn "brightnessctl" "--class=backlight" "set" "10%-";
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
          natural-scroll = true;
        };

        mouse = {
          accel-profile = "flat";
        };
      };

      layout = {
        gaps = 8;

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

        focus-ring = {
          width = 1;
          active = {
            color = "#7fc8ff";
          };
          inactive = {
            color = "#505050";
          };
        };

        shadow = {
          enable = true;
          softness = 30;
          spread = 4;
        };
      };
    };

    programs.waybar = {
      enable = true;
      systemd.enable = true;

      style = ./waybar/style.css;

      settings.mainBar = lib.mkMerge [
        {
          layer = "top";
          position = "top";

          margin-top = 4;
          margin-left = 15;
          margin-bottom = 4;
          margin-right = 15;
          spacing = 0;

          mod = "dock";

          reload_style_on_change = true;
        }
        (import ./waybar/modules.nix)
      ];
    };

    # notifications
    services.mako.enable = true;

    # the temu raycast thingie
    programs.fuzzel.enable = true;

    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-plugin;
      settings = {
        command = "${pkgs.windowtolayer}/bin/windowtolayer -- ${pkgs.ghostty}/bin/ghostty -e ${pkgs.asciiquarium}/bin/asciiquarium";
      };
    };
  };
}
