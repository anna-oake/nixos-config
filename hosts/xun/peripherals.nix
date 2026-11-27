{ config, pkgs, ... }:
let
  app = pkgs.callPackage ./peripherals-app { };
in
{
  users.users.peripherals = {
    isNormalUser = true;
    description = "Tablet hardware test session";
  };

  services.cage = {
    enable = true;
    user = "peripherals";
    program = "${app}/bin/xun-peripherals";
    restartIfChanged = true;
  };

  services.logind.settings.Login.HandlePowerKey = "ignore";
  services.upower.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.extraConfig."60-xun-volume"."wireplumber.settings" = {
      "device.routes.default-sink-volume" = 1.0;
    };
  };
  systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 =
    config.environment.sessionVariables.ALSA_CONFIG_UCM2;
}
