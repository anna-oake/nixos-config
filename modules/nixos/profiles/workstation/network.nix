{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.enable {
    networking.networkmanager.enable = true;

    # mdns
    services.avahi.enable = lib.mkDefault false;
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

    # wifi
    age.secrets.wifi-home = { };
    networking.networkmanager.ensureProfiles = {
      environmentFiles = [
        config.age.secrets.wifi-home.path
      ];

      profiles = {
        Home = {
          connection = {
            id = "$HOME_SSID";
            type = "wifi";
          };
          wifi = {
            mode = "infrastructure";
            ssid = "$HOME_SSID";
          };
          wifi-security = {
            key-mgmt = "sae";
            psk = "$HOME_PSK";
          };
        };
      };
    };
  };
}
