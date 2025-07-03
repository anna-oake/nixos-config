{
  lib,
  ...
}:
{
  # localisation
  i18n.defaultLocale = "en_GB.UTF-8";
  services.xserver.xkb.layout = "us";

  # timezone
  services.automatic-timezoned.enable = true;
  services.geoclue2.enableDemoAgent = lib.mkForce true;
  services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate";
}
