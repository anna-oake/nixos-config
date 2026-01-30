{
  config,
  lib,
  ...
}:
let
  wifiSecrets = [
    "home"
    "maeve"
  ];
in
{
  options.profiles.workstation.wifi.enable = lib.mkEnableOption "Wi-Fi workstation profile";

  config = lib.mkIf config.profiles.workstation.wifi.enable {
    profiles.workstation.enable = lib.mkForce true;

    boot.extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom="NL"
    '';

    age.secrets = lib.genAttrs (map (name: "wifi/${name}") wifiSecrets) (_: { });

    # wifi
    networking.networkmanager.ensureProfiles = {
      environmentFiles = map (name: config.age.secrets."wifi/${name}".path) wifiSecrets;

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

        Maeve = {
          connection = {
            id = "$MAEVE_SSID";
            type = "wifi";
          };
          wifi = {
            mode = "infrastructure";
            ssid = "$MAEVE_SSID";
          };
          wifi-security = {
            key-mgmt = "sae";
            psk = "$MAEVE_PSK";
          };
        };
      };
    };
  };
}
