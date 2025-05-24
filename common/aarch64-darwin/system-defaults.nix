{ config, ... }:
{
  /*
    TODO: possibly create a nice dock setup and apply it? the mess with GUIDs doesnt look great
  */

  system.defaults = {
    CustomUserPreferences = {
      "com.apple.menuextra.clock" = {
        ShowSeconds = true;
      };
      "com.apple.WindowManager" = {
        EnableStandardClickToShowDesktop = false;
      };
      NSGlobalDomain = {
        NSQuitAlwaysKeepsWindow = false;
      };

      # the following basically removes the default ABC keyboard layout since we only use 3rd-party ones
      "com.apple.HIToolbox" = {
        AppleEnabledInputSources = [
          {
            "Bundle ID" = "com.apple.CharacterPaletteIM";
            InputSourceKind = "Non Keyboard Input Method";
          }
        ];
      };
    };

    LaunchServices.LSQuarantine = false; # do not quarantine downloaded applications

    NSGlobalDomain = {
      NSDocumentSaveNewDocumentsToCloud = false;
    };

    finder = {
      AppleShowAllFiles = true; # show hidden files
      AppleShowAllExtensions = true;
      NewWindowTarget = "Computer";
      _FXSortFoldersFirst = false;
      FXEnableExtensionChangeWarning = false;
      FXDefaultSearchScope = "SCcf"; # search in This Folder byd efault
      FXPreferredViewStyle = "Nlsv"; # list style
      ShowPathbar = true; # show pathbar at the bottom of the window
      QuitMenuItem = true;
    };

    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.3;
      largesize = 72; # magnification size
      tilesize = 28; # unmagnified size
      orientation = "bottom";
      magnification = true;
      show-recents = false;
    };

    loginwindow = {
      LoginwindowText = "Please contact ${config.me.email}";
    };

    WindowManager = {
      EnableTiledWindowMargins = false;
      EnableTilingByEdgeDrag = true;
    };

    trackpad = {
      Clicking = true; # tap-to-click
      TrackpadThreeFingerDrag = true;
    };
  };
}
