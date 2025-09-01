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
  options.users.me.enable = mkEnableOption "default user";
  config = {
    users.mutableUsers = false;
    users.groups.users.gid = 100;

    age.secrets = lib.optionalAttrs cfg.me.enable {
      "user-password".rekeyFile = "${inputs.self}/secrets/secrets/user-password.age";
    };

    users.users = {
      ${config.me.username} = mkIf cfg.me.enable (
        {
          isNormalUser = true;
          uid = 1000;
          group = "users";
          extraGroups = [
            "wheel" # sudo
            "networkmanager" # network configuration
            "video"
            "netbird"
          ];
          openssh.authorizedKeys.keys = [
            config.me.sshKey
          ];
        }
        // (
          if config.age.ready then
            {
              hashedPasswordFile = config.age.secrets.user-password.path;
            }
          else
            {
              hashedPassword = "$y$jFT$lTj/bGjovSblBCbRkgWV61$F1qpaiSf7L7BawAOW5tJ0RnAH2.zCTPTsWsMcayoI7A";
            }
        )
      );
    };
  };
}
