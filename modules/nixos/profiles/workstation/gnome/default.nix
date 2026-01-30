{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.profiles.workstation.gnome;

  mkDockOption =
    default:
    lib.mkOption (
      with lib.types;
      {
        inherit default;
        type = listOf (strMatching "^.*\.desktop$");
        description = "GNOME dock favourite items";
      }
    );
in
{
  options.profiles.workstation.gnome = {
    enable = lib.mkEnableOption "GNOME workstation profile";
    dockItems = {
      left = mkDockOption [
        "microsoft-edge.desktop"
        "org.telegram.desktop.desktop"
        "discord.desktop"
      ];
      middle = mkDockOption [ ];
      right = mkDockOption [
        "1password.desktop"
        "code.desktop"
        "org.gnome.Console.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    powerButtonAction = lib.mkOption {
      type = lib.types.str;
      default = "hibernate";
      description = "Power button action";
    };

    shellExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      description = "List of packages containing GNOME Shell Extensions to install.";
      default =
        with pkgs;
        with pkgs.gnomeExtensions;
        [
          user-themes
          just-perfection
          appindicator
        ];
    };
  };

  config = lib.mkIf cfg.enable {
    profiles.workstation.enable = lib.mkForce true;
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;
    services.xserver.enable = true;

    # M365 sync
    services.gnome.evolution-data-server.plugins = [ pkgs.evolution-ews ];

    # fix crash on fast login (nixpkgs/issues/103746)
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    environment.systemPackages =
      with pkgs;
      [
        gnome-tweaks
        lion-theme
        breezex-cursor
      ]
      ++ cfg.shellExtensions;

    # systemd.user.services.libinput-three-finger-drag = {
    #   description = "three-finger-drag daemon";
    #   wantedBy = [ "default.target" ];
    #   after = [ "graphical-session-pre.target" ];

    #   serviceConfig = {
    #     ExecStart = "${libinput-three-finger-drag}/bin/libinput-three-finger-drag";
    #     Type = "simple";
    #     Restart = "always";
    #   };
    # };

    # environment variables
    environment.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "flatpak"; # fix telegram filepicker
    };

    # remove redundant gnome packages
    environment.gnome.excludePackages = with pkgs; [
      epiphany
      gnome-tour
      geary
      gnome-contacts
      snapshot
      simple-scan
      yelp
    ];

    # profile picture
    boot.postBootCommands =
      let
        username = config.me.username;
        pfp = inputs.self + /assets/pfp.jpg;
      in
      ''
        echo -e "[User]\nIcon=${pfp}\n" > /var/lib/AccountsService/users/${username}
      '';

    fonts.packages = with pkgs; [
      cantarell-fonts
    ];

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;
          settings = {
            # behaviour
            "org/gnome/mutter" = {
              dynamic-workspaces = true;
              edge-tiling = true;
              experimental-features = [ "scale-monitor-framebuffer" ];
              workspaces-only-on-primary = true;
            };
            "org/gnome/desktop/wm/preferences" = {
              auto-raise = false;
              focus-mode = "sloppy";
              titlebar-font = "Cantarell Bold 11";
            };
            "org/gnome/desktop/peripherals/mouse" = {
              accel-profile = "flat";
            };

            # time & date
            "org/gnome/desktop/datetime" = {
              automatic-timezone = true;
            };
            "org/gnome/system/location" = {
              enabled = true;
            };

            # power & sleep
            "org/gnome/settings-daemon/plugins/power" = {
              power-button-action = cfg.powerButtonAction;
              sleep-inactive-battery-type = "hibernate";
              sleep-inactive-ac-type = "nothing";
            };

            # dock & extensions
            "org/gnome/shell" = {
              favorite-apps = with cfg.dockItems; left ++ middle ++ right;
              enabled-extensions = map (p: p.extensionUuid) cfg.shellExtensions;
            };

            # appearance
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              cursor-theme = "BreezeX-Black";
              enable-hot-corners = false;
              gtk-enable-primary-paste = false;
              show-battery-percentage = true;
              clock-show-seconds = true;
              font-name = "Cantarell 11";
              document-font-name = "Cantarell 11";
            };
            "org/gnome/shell/extensions/user-theme" = {
              name = "Lion";
            };
            "org/gnome/desktop/background" = {
              picture-uri-dark = "file://${inputs.self + /assets/wallpaper.jpg}";
            };
            "org/gnome/shell/extensions/just-perfection" = {
              events-button = true;
              invert-calendar-column-items = true;
              quick-settings-dark-mode = false;
              quick-settings-night-light = false;
              search = false;
              show-apps-button = false;
              switcher-popup-delay = false;
              window-preview-caption = false;
              world-clock = false;
              support-notifier-type = lib.gvariant.mkInt32 0;
            };

            # keybinds
            "org/gnome/settings-daemon/plugins/media-keys" = {
              custom-keybindings = [
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
              ];
              screensaver = [ "<Shift><Super>x" ];
              search = [ "<Super>space" ];
            };
            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
              binding = "<Super>Return";
              command = "kgx";
              name = "run terminal";
            };
            "org/gnome/desktop/wm/keybindings" = {
              close = [ "<Shift><Super>q" ];
              maximize = [
                "<Shift><Super>Up"
                "<Shift><Super>L"
              ];
              move-to-monitor-down = [ "<Shift><Control><Super>K" ];
              move-to-monitor-left = [ "<Shift><Control><Super>J" ];
              move-to-monitor-right = [ "<Shift><Control><Super>semicolon" ];
              move-to-monitor-up = [ "<Shift><Control><Super>L" ];
              move-to-workspace-1 = [ "<Shift><Super>1" ];
              move-to-workspace-2 = [ "<Shift><Super>2" ];
              move-to-workspace-3 = [ "<Shift><Super>3" ];
              move-to-workspace-4 = [ "<Shift><Super>4" ];
              move-to-workspace-5 = [ "<Shift><Super>5" ];
              move-to-workspace-6 = [ "<Shift><Super>6" ];
              move-to-workspace-7 = [ "<Shift><Super>7" ];
              move-to-workspace-8 = [ "<Shift><Super>8" ];
              move-to-workspace-9 = [ "<Shift><Super>9" ];
              switch-to-workspace-1 = [ "<Super>1" ];
              switch-to-workspace-2 = [ "<Super>2" ];
              switch-to-workspace-3 = [ "<Super>3" ];
              switch-to-workspace-4 = [ "<Super>4" ];
              switch-to-workspace-5 = [ "<Super>5" ];
              switch-to-workspace-6 = [ "<Super>6" ];
              switch-to-workspace-7 = [ "<Super>7" ];
              switch-to-workspace-8 = [ "<Super>8" ];
              switch-to-workspace-9 = [ "<Super>9" ];
              move-to-workspace-left = [ "<Shift><Control><Super>Left" ];
              move-to-workspace-right = [ "<Shift><Control><Super>Right" ];
              switch-input-source = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-input-source-backward = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              toggle-fullscreen = [ "<Super>f" ];
              unmaximize = [
                "<Shift><Super>Down"
                "<Shift><Super>K"
              ];
            };
            "org/gnome/mutter/keybindings" = {
              toggle-tiled-left = [
                "<Shift><Super>Left"
                "<Shift><Super>J"
              ];
              toggle-tiled-right = [
                "<Shift><Super>Right"
                "<Shift><Super>semicolon"
              ];
            };
            "org/gnome/shell/keybindings" = {
              focus-active-notification = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-1 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-2 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-3 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-4 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-5 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-6 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-7 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-8 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              switch-to-application-9 = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              toggle-application-view = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
              toggle-message-tray = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
            };
          };
        }
      ];
    };
  };
}
