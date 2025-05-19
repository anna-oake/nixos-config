{ ... }:
{
  /*
    TODO: fix typography layout! right now, only the *last* in the EnabledThirdPartyInputSources list is actually "applied"
          also look into pretty names (ask anya how she does it)

          possibly create a nice dock setup and apply it? the mess with GUIDs doesnt look great
  */

  system.defaults = {
    CustomUserPreferences = {
      "com.apple.menuextra.clock" = {
        ShowSeconds = true;
      };
      "com.apple.WindowManager" = {
        EnableStandardClickToShowDesktop = false;
      };
    };

    LaunchServices.LSQuarantine = false; # do not quarantine downloaded applications

    CustomSystemPreferences = {
      "com.apple.inputsources" = {
        AppleEnabledThirdPartyInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = "-9876";
            "KeyboardLayout Name" = "English \\U2013 Ilya Birman Typography";
          }
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = "-31553";
            "KeyboardLayout Name" = "Russian \\U2013 Ilya Birman Typography";
          }
        ];
      };

      "com.apple.HIToolbox" = {
        AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.British-PC";
        AppleEnabledInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 250;
            "KeyboardLayout Name" = "British-PC";
          }
        ];
        AppleSelectedInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 250;
            "KeyboardLayout Name" = "British-PC";
          }
        ];
      };
    };

    finder = {
      AppleShowAllFiles = true; # show hidden files
      NewWindowTarget = "Computer"; # default finder location
      ShowPathbar = true; # show pathbar at the bottom of the window
      QuitMenuItem = true; # allow quit
    };

    dock = {
      autohide = true;
      autohide-delay = 0.0;
      largesize = 72; # magnification size
      tilesize = 28; # unmagnified size
      orientation = "bottom";
      magnification = true;
      show-recents = false;
    };

    loginwindow = {
      LoginwindowText = "sex";
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
