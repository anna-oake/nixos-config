{
  lib,
  config,
  ...
}:
let
  goodDefaults = {
    browseable = true;
    writable = true;
    "delete veto files" = true;
    "inherit permissions" = true;
    "spotlight" = true;
    "veto files" = "/._*/.DS_Store/";
  };
in
{
  options.share = {
    serverString = lib.mkOption {
      type = lib.types.str;
      default = "share";
    };
    extraShares = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };
  config = {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server string" = config.share.serverString;
          "netbios name" = "share";
          "access based share enum" = true;
          "fruit:encoding" = "native";
          "fruit:metadata" = "stream";
          "fruit:zero_file_id" = true;
          "fruit:nfs_aces" = false;
          "map to guest" = "never";
          "spotlight backend" = "tracker";
          "guest ok" = false;
          "vfs objects" = "catia fruit streams_xattr";
        };
        homes = {
          "valid users" = "%S";
        }
        // goodDefaults;
      }
      // lib.mapAttrs (
        name: path:
        {
          "valid users" = "@share-${name}";
          "path" = path;
        }
        // goodDefaults
      ) config.share.extraShares;
    };
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    system.activationScripts.samba-sync-users =
      let
        smb = config.services.samba.package;
        pdb = "${smb}/bin/pdbedit";
      in
      ''
        sync_user() {
          u="$1"; f="/run/agenix/lxc-share/$u-samba-password"
          [ -f "$f" ] || return 1
          hash="$(tr -d '\r\n' < "$f")"
          printf 'bogus\nbogus\n' | ${pdb} -a -u "$u" -t >/dev/null
          ${pdb} -u "$u" --set-nt-hash "$hash" >/dev/null
        }

        ${lib.concatStringsSep "\n" (map (u: "sync_user ${u}") (builtins.attrNames config.share.users))}
      '';
  };
}
