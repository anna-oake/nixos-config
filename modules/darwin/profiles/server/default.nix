{
  config,
  lib,
  ...
}:
{
  imports = [
    ./system-defaults.nix
  ];

  config = lib.mkIf config.profiles.server.enable {
    # the following doesn't seem to work, it enables screen sharing but connection fails. re-enabling with GUI helps
    system.activationScripts.postActivation.text = ''
      echo "Enabling Screen Sharing (VNC)..."
      launchctl enable system/com.apple.screensharing
      launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist \
        2>/dev/null || true
    '';

    system.pmset.all = {
      displaysleep = 0;
      disksleep = 0;
      sleep = 0;
      womp = 1;
      powernap = 0;
      autorestart = 1;
      acwake = 1;
    };
  };
}
