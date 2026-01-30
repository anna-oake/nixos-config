{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.enable {
    networking.networkmanager.enable = true;

    # mdns
    services.avahi.enable = false;
    services.resolved.enable = true;

    # firewall
    networking.firewall.enable = false;

    # netbird
    age.secrets.netbird-personal = {
      owner = "netbird";
      group = "netbird";
    };

    services.netbird.simple = {
      enable = true;
      managementUrl = "https://net.oa.ke";
      setupKeyFile = config.age.secrets.netbird-personal.path;
    };

    services.openssh.settings.PasswordAuthentication = false;
  };
}
