{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.server.enable {
    system.defaults = {
      CustomUserPreferences = {
        "com.apple.loginwindow" = {
          # Do not save app state on shutdown
          TALLogoutSavesState = false;
          # Do not reopen apps from saved state on login
          LoginwindowLaunchesRelaunchApps = false;
        };
      };
    };
  };
}
