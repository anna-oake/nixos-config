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

  # tailscale
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # wifi
  age.secrets.wifi-home.file = (inputs.self + /secrets/wifi-home.age);
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
