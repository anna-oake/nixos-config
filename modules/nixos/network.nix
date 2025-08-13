{
  config,
  inputs,
  ...
}:
{
  networking.networkmanager.enable = true;

  # mdns
  services.avahi.enable = false;
  services.resolved.enable = true;

  # ssh
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # firewall
  networking.firewall.enable = false;

  # netbird
  age.secrets.netbird-personal = {
    rekeyFile = (inputs.self + /secrets/netbird-personal.age);
    owner = "netbird";
    group = "netbird";
  };

  services.netbird.simple = {
    enable = true;
    managementUrl = "https://net.oa.ke";
    setupKeyFile = config.age.secrets.netbird-personal.path;
  };

  # wifi
  age.secrets.wifi-home.rekeyFile = (inputs.self + /secrets/wifi-home.age);
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
}
