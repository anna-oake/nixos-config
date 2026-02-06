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
        "Mod+L".action = spawn "swaylock";
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

    # some bar thing??
    programs.waybar = {
      enable = true;
      systemd.enable = true;

      style = ./style.css;

      settings.mainBar = {
        layer = "top";
        position = "top";
        mod = "dock";
        margin-left = 15;
        margin-right = 15;
        margin-top = 4;
        margin-bottom = 4;
        reload_style_on_change = true;
        spacing = 0;
        modules-left = [
          # "custom/spacer"
          "image"
          "wlr/taskbar"
          "niri/window"
          "custom/window-icon"
        ];
        modules-center = [
          "niri/workspaces"
        ];
        modules-right = [
          "custom/clock-icon"
          "clock"
          "custom/tray-icon"
          "memory"
          "cpu"
          "backlight"
          "battery"
          "network"
          # "custom/vpn"
          "idle_inhibitor"
          "pulseaudio"
          "tray"
        ];

        # Module configuration: Left
        "custom/spacer" = {
          format = "   ";
          on-click = "niri msg action toggle-overview";
        };
        "image" = {
          path = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
          on-click = "niri msg action toggle-overview";
          size = 22;
          tooltip = false;
        };
        "niri/workspaces" = {
          all-outputs = false;
          on-click = "activate";
          current-only = false;
          disable-scroll = false;
          icon-theme = "Papirus-Dark";
          format = "<span><b>{icon}</b></span>";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
          };
        };
        "wlr/taskbar" = {
          all-outputs = false;
          format = "{icon}";
          icon-theme = "Papirus-Dark";
          icon-size = 16;
          tooltip = true;
          tooltip-format = "{title}";
          active-first = true;
          on-click = "activate";
        };
        "hyprland/window" = {
          max-length = 50;
          format = "<i>{title}</i>";
          separate-outputs = true;
          icon = true;
          icon-size = 13;
        };
        "niri/window" = {
          max-length = 50;
          format = "{app_id}";
          separate-outputs = true;
          on-click = "walker --modules windows";
          # icon = true;
          # icon-size = 18;
          rewrite = {
            "" = "<span foreground='#89b4fa'> Niri</span>";
            " " = "<span foreground='#89b4fa'> Niri</span>";
            # terminals
            "com.mitchellh.ghostty" = "<span foreground='#89b4fa'>󰊠 Ghostty</span>";
            "org.wezfurlong.wezterm" = "<span foreground='#89b4fa'> Wezterm</span>";
            "kitty" = "<span foreground='#89b4fa'>󰄛 Kitty</span>";
            # code
            "code" = "<span foreground='#89b4fa'>󰨞 Code</span>";
            "Cursor" = "<span foreground='#89b4fa'>󰨞 Cursor</span>";
            # browsers
            "brave-browser" = "<span foreground='#89b4fa'> Brave</span>";
            "Vivaldi-stable" = "<span foreground='#89b4fa'> Vivaldi</span>";
            "firefox" = "<span foreground='#89b4fa'> Firefox</span>";
            "zen" = "<span foreground='#89b4fa'> Zen</span>";
            # gnome/gtk
            "org.gnome.Nautilus" = "<span foreground='#89b4fa'>󰪶 Files</span>";
            # misc
            "spotify" = "<span foreground='#89b4fa'> Spotify</span>";
            "Slack" = "<span foreground='#89b4fa'> Slack</span>";
            "signal" = "<span foreground='#89b4fa'>󰭹 Signal</span>";
            # Productivity
            "Morgen" = "<span foreground='#89b4fa'> Morgen</span>";
            "org.kde.okular" = "<span foreground='#89b4fa'> Okular</span>";
            "tana" = "<span foreground='#89b4fa'>󰠮 Tana</span>";
            "obsidian" = "<span foreground='#89b4fa'>󰠮 Obsdian</span>";
            "Zotero" = "<span foreground='#89b4fa'>󰬡 Zotero</span>";
            "org.pulseaudio.pavucontrol" = "<span foreground='#89b4fa'> Pavucontrol</span>";
            # Everything else
            "(.*)" = "<span foreground='#89b4fa'>$1</span>";
          };
        };

        # Module configuration: Center
        clock = {
          format = "<b>{:%a %b[%m] %d ▒ %I:%M %p}</b>";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%H:%M %Y-%m-%d}";
        };

        # Module configuration: Right
        pulseaudio = {
          format = "{icon}";
          format-bluetooth = "󰂰";
          format-muted = "";
          tooltip-format = "{name} {volume}%";
          format-icons = {
            "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
            "alsa_output.pci-0000_00_1f.3.analog-stereo-muted" = "";
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            phone-muted = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
            ];
          };
          scroll-step = 1;
          on-click = "pavucontrol";
        };
        network = {
          format-wifi = " ";
          format-ethernet = " ";
          tooltip-format = "{essid} ({signalStrength}%)";
          format-linked = "󰛵 ";
          format-disconnected = "󰅛 ";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };
        memory = {
          interval = 1;
          rotate = 270;
          format = "{icon}";
          format-icons = [
            "<span color='#b4befe'>󰝦</span>"
            "<span color='#b4befe'>󰪞</span>"
            "<span color='#a6e3a1'>󰪟</span>"
            "<span color='#a6e3a1'>󰪠</span>"
            "<span color='#f9e2af'>󰪡</span>"
            "<span color='#fab387'>󰪢</span>"
            "<span color='#eba0ac'>󰪣</span>"
            "<span color='#f38ba8'>󰪤</span>"
            "<span color='#f38ba8'>󰪥</span>"
          ];
          max-length = 10;
        };
        cpu = {
          interval = 1;
          format = "{icon}";
          rotate = 270;
          format-icons = [
            "<span color='#b4befe'>󰝦</span>"
            "<span color='#b4befe'>󰪞</span>"
            "<span color='#a6e3a1'>󰪟</span>"
            "<span color='#a6e3a1'>󰪠</span>"
            "<span color='#f9e2af'>󰪡</span>"
            "<span color='#fab387'>󰪢</span>"
            "<span color='#eba0ac'>󰪣</span>"
            "<span color='#f38ba8'>󰪤</span>"
            "<span color='#f38ba8'>󰪥</span>"
          ];
        };
        backlight = {
          format = "{icon}";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
        };
        battery = {
          states = {
            # good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{icon}";
          format-charging = "";
          format-plugged = "";
          format-alt = "{capacity}% {icon}";
          # format-icons = ["" "" "" "" "" "" "" ""];
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          tooltip-format = "{capacity}% {time}";
          tooltip = true;
        };
        "battery#bat2" = {
          bat = "BAT2";
        };
        tray = {
          icon-size = 18;
          spacing = 10;
        };
        "idle_inhibitor" = {
          format = "<i>{icon}</i>";
          start-activated = false;
          format-icons = {
            activated = " ";
            deactivated = " ";
          };
          tooltip-format-activated = "Swayidle inactive";
          tooltip-format-deactivated = "Swayidle active";
        };
        mpris = {
          interval = 2;
          format = "{player_icon}{dynamic}{status_icon}";
          format-paused = "{player_icon}{dynamic}{status_icon}";
          tooltip = true;
          tooltip-format = "{dynamic}";
          on-click = "playerctl play-pause";
          on-click-middle = "playerctl previous";
          on-click-right = "playerctl next";
          scroll-step = 5.0;
          smooth-scrolling-threshold = 1;
          dynamic-len = 30;
          player-icons = {
            chromium = " ";
            brave-browser = " ";
            default = " ";
            firefox = " ";
            kdeconnect = " ";
            mopidy = " ";
            mpv = "󰐹 ";
            spotify = " ";
            vlc = "󰕼 ";
          };
          status-icons = {
            playing = "";
            paused = "";
            stopped = "";
          };
        };
        # Custom icons
        "custom/toggl-icon" = {
          format = "󱎫";
        };
        "custom/audio-icon" = {
          format = "";
        };
        "custom/network-icon" = {
          format = "󰖩";
        };
        "custom/backlight-icon" = {
          format = "󰌵";
        };
        "custom/battery-icon" = {
          format = "󰁹";
        };
        "custom/clock-icon" = {
          format = "";
        };
        "custom/mpris-icon" = {
          format = " ";
        };
        "custom/idle-icon" = {
          format = " ";
        };
        # "custom/vpn-icon" = {
        #   format = " ";
        # };
        "custom/tray-icon" = {
          format = "󱊖";
          on-click = "swaync-client -t";
          tooltip = "Notification center";
        };
        "custom/window-icon" = {
          format = " ";
          on-click = "walker --modules windows";
          tooltip = "Window list";
        };
      };
    };

    # notifications
    services.mako.enable = true;

    # the temu raycast thingie
    programs.fuzzel.enable = true;

    programs.swaylock.enable = true;
  };
}
