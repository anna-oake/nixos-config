{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.enable {
    i18n.defaultLocale = "en_GB.UTF-8";
    services.xserver.xkb.layout = "us";
  };
}
