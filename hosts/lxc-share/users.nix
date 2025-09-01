{
  config,
  lib,
  inputs,
  ...
}:
let
  mapShareUser = name: user: {
    inherit name;
    inherit (user) uid;
    isNormalUser = true;
    home = "${config.share.homes}/${name}";
    openssh.authorizedKeys.keys = lib.mkIf (user.sshKey != null) [ user.sshKey ];
    hashedPasswordFile = config.age.secrets."lxc-share/${name}-unix-password".path;
    extraGroups = map (share: "share-${share}") user.allowedExtraShares;
  };
in
{
  options.share = {
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
  config = {
    users.groups =
      lib.genAttrs (map (share: "share-${share}") (lib.attrNames config.share.extraShares)) (share: { })
      // {
        users.gid = 100;
      };

    users.users = lib.mapAttrs (name: user: mapShareUser name user) config.share.users;
    age.secrets =
      lib.genAttrs
        (lib.concatMap (name: [
          "lxc-share/${name}-unix-password"
          "lxc-share/${name}-samba-password"
        ]) (lib.attrNames config.share.users))
        (secretName: {
          rekeyFile = "${inputs.self}/secrets/secrets/${secretName}.age";
        });
  };
}
