{
  lib,
  pkgs,
  ...
}:
let
  openrgb = pkgs.openrgb.withPlugins [
    pkgs.openrgb-plugin-steam-sink
  ];
in
{
  hardware.leds-valve-shim.enable = true;

  environment.systemPackages = [
    openrgb
  ];

  services.udev.packages = [
    openrgb
  ];

  systemd.user.services.openrgb = {
    description = "OpenRGB";
    after = [ "gamescope-session.service" ];
    partOf = [ "gamescope-session.target" ];
    wantedBy = [ "gamescope-session.target" ];

    environment = {
      QT_QPA_PLATFORM = "xcb";
    };

    serviceConfig = {
      EnvironmentFile = "%t/gamescope-environment";
      ExecStart = "${lib.getExe openrgb} --startminimized";
      Restart = "on-failure";
    };
  };
}
