{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.lxc.profiles.share;
  mapShareUser = name: user: {
    inherit name;
    inherit (user) uid;
    isNormalUser = true;
    home = "${cfg.homes}/${name}";
    openssh.authorizedKeys.keys = lib.mkIf (user.sshKey != null) [ user.sshKey ];
    hashedPasswordFile = config.age.secrets."${cfg.secretsDomain}/${name}-unix-password".path;
    extraGroups = map (share: "share-${share}") user.allowedExtraShares;
  };
in
{
  options.lxc.profiles.share = {
    homes = lib.mkOption {
      type = lib.types.str;
      default = "/storage/share";
    };
    users = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            sshKey = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            uid = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
            };
            allowedExtraShares = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
    };
  };
  config = lib.mkIf cfg.enable {
    users.groups =
      lib.genAttrs (map (share: "share-${share}") (lib.attrNames cfg.extraShares)) (share: { })
      // {
        users.gid = 100;
      };

    users.users = lib.mapAttrs (name: user: mapShareUser name user) cfg.users;
    age.secrets =
      lib.genAttrs
        (lib.concatMap (name: [
          "${cfg.secretsDomain}/${name}-unix-password"
          "${cfg.secretsDomain}/${name}-samba-password"
        ]) (lib.attrNames cfg.users))
        (secretName: {
          rekeyFile = "${inputs.self}/secrets/secrets/${secretName}.age";
        });
  };
}
