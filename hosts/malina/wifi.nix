{
  config,
  ...
}:
{
  age.secrets."wifi/home" = { };

  networking.networkmanager = {
    enable = true;

    ensureProfiles = {
      environmentFiles = [ config.age.secrets."wifi/home".path ];

      profiles = {
        malina-iot-5 = {
          connection = {
            id = "$IOT_5_SSID";
            type = "wifi";
          };
          wifi = {
            hidden = true;
            mode = "infrastructure";
            ssid = "$IOT_5_SSID";
          };
          wifi-security = {
            "key-mgmt" = "wpa-psk";
            psk = "$IOT_5_PSK";
          };
        };
      };
    };
  };
}
