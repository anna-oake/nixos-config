{
  config,
  pkgs,
  ...
}:
{
  system.activationScripts.postActivation.text = ''
    sudo -u ${config.me.username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  system.defaults = {
    NSGlobalDomain = {
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;
    };

    screensaver = {
      # TODO: this is actually broken - https://github.com/nix-darwin/nix-darwin/issues/908
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    CustomUserPreferences = {
      NSGlobalDomain = {
        WebKitDeveloperExtras = true;
      };

      "com.apple.menuextra.clock" = {
        ShowSeconds = true;
      };
      "com.apple.WindowManager" = {
        EnableStandardClickToShowDesktop = false;
      };

      "com.apple.TextInputMenu" = {
        visible = true;
      };

      "com.apple.Safari" = {
        AutoFillCreditCardData = false;
        AutoFillFromAddressBook = false;
        AutoFillFromiCloudKeychain = false;
        AutoFillMiscellaneousForms = false;
        AutoFillPasswords = false;
        ShowOverlayStatusBar = true;
        AutoOpenSafeDownloads = false;
        IncludeDevelopMenu = true;
        IncludeInternalDebugMenu = true;
        ShowDevelopMenu = 1;
        WebKitDeveloperExtrasEnabledPreferenceKey = true;
        "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
      };

      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # screenshot stuff
          "184".enabled = false;
          "28".enabled = false;
          "29".enabled = false;
          "30".enabled = false;
          "31".enabled = false;
          # Spotlight Search
          "64".enabled = false;
          # Finder search window
          "65".enabled = false;
          # Set 'Cmd + Space' for layout switcher
          "60" = {
            enabled = true;
            value = {
              parameters = [
                32
                49
                1048576
              ];
              type = "standard";
            };
          };
        };
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

      "com.apple.AppleMultitouchTrackpad" = {
        TrackpadThreeFingerVertSwipeGesture = false;
        TrackpadFourFingerVertSwipeGesture = 2;
      };

      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
        TrackpadThreeFingerVertSwipeGesture = false;
        TrackpadFourFingerVertSwipeGesture = 2;
      };

      "com.apple.dock" = {
        showMissionControlGestureEnabled = true;
        showAppExposeGestureEnabled = true;
      };

      "com.apple.desktopservices" = {
        # Avoid creating .DS_Store files on USB or network volumes
        DSDontWriteUSBStores = true;
        DSDontWriteNetworkStores = true;
      };

      "com.apple.frameworks.diskimages" = {
        # Disable disk image verification
        skip-verify = true;
        skip-verify-locked = true;
        skip-verify-remote = true;
      };

      "com.apple.AdLib" = {
        # Disable personalized advertising
        forceLimitAdTracking = true;
        allowApplePersonalizedAdvertising = false;
        allowIdentifierForAdvertising = false;
      };

      "com.apple.CrashReporter" = {
        # Disable crash reporter
        DialogType = "none";
      };
    };

    CustomSystemPreferences = {
      "com.apple.CoreBrightness"."DisplayPreferences"."37D8832A-2D66-02CA-B9F7-8F30A301B230" = {
        AutoBrightnessEnable = false;
      };
    };

    LaunchServices.LSQuarantine = false; # do not quarantine downloaded applications

    finder = {
      AppleShowAllFiles = true; # show hidden files
      AppleShowAllExtensions = true;
      NewWindowTarget = "Computer";
      _FXSortFoldersFirst = false;
      FXEnableExtensionChangeWarning = false;
      FXDefaultSearchScope = "SCcf"; # search in This Folder by default
      FXPreferredViewStyle = "Nlsv"; # list style
      ShowPathbar = true; # show pathbar at the bottom of the window
      QuitMenuItem = true;
    };

    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.3;
      tilesize = 70;
      orientation = "bottom";
      magnification = false;
      show-recents = false;
      # top left hot corner - start screen saver
      wvous-tl-corner = 5;
      # bottom right hot corner - do nothing
      wvous-br-corner = 1;
      persistent-apps = [
        "/System/Cryptexes/App/System/Applications/Safari.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/Mail.app"
        "/Applications/Nix Apps/Spotify.app"
        "/Applications/Telegram.app"
        "/Applications/Nix Apps/Slack.app"
        "/Applications/Ghostty.app"
        "${pkgs.zed-editor}/Applications/Zed.app"
        "/Applications/Nix Apps/ChatGPT.app"
        "/Applications/Modrinth App.app"
      ];
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

    controlcenter = {
      NowPlaying = false;
      Sound = true;
    };
  };
}
