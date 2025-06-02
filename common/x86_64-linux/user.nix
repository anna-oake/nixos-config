{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.users;
in
{
  options.users = {
    user = mkEnableOption "default user";
    kiosk = mkEnableOption "kiosk user";
  };
  config = {
    users.mutableUsers = false;
    users.groups.users.gid = 100;

    age.secrets =
      lib.optionalAttrs cfg.user {
        "user-password".file = "${inputs.self}/secrets/user-password.age";
      }
      // lib.optionalAttrs cfg.kiosk {
        "kiosk-password".file = "${inputs.self}/secrets/kiosk-password.age";
      };

    users.users = {
      ${config.me.username} = mkIf cfg.user {
        isNormalUser = true;
        uid = 1000;
        group = "users";
        extraGroups = [
          "wheel" # sudo
          "networkmanager" # network configuration
          "video"
        ];

        hashedPasswordFile = config.age.secrets.user-password.path;
        openssh.authorizedKeys.keys = config.me.sshKeys;
      };

      kiosk = mkIf cfg.kiosk {
        isNormalUser = true;
        uid = 1111;
        group = "users";
        extraGroups = [
          "wheel"
          "video"
          "audio"
          "input"
        ];

        hashedPasswordFile = config.age.secrets.kiosk-password.path;
        openssh.authorizedKeys.keys = config.me.sshKeys;
      };
    };
  };
}
