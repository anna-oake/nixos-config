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
  cfg = config.lxc.profiles.share;
in
{
  options.lxc.profiles.share = {
    serverString = lib.mkOption {
      type = lib.types.str;
      default = "share";
    };
    extraShares = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };
  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server string" = cfg.serverString;
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
      ) cfg.extraShares;
    };
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    systemd.services.samba-sync-users = {
      description = "Load samba user hashes from agenix";

      wantedBy = [ "samba.target" ];
      partOf = [ "samba-smbd.service" ];
      requires = [ "samba-smbd.service" ];
      after = [ "samba-smbd.service" ];

      script =
        let
          smb = config.services.samba.package;
          pdb = "${smb}/bin/pdbedit";
        in
        ''
          sync_user() {
            u="$1"; f="/run/agenix/${cfg.secretsDomain}/$u-samba-password"
            [ -f "$f" ] || return 1
            hash="$(tr -d '\r\n' < "$f")"
            printf 'bogus\nbogus\n' | ${pdb} -a -u "$u" -t >/dev/null
            ${pdb} -u "$u" --set-nt-hash "$hash" >/dev/null
          }

          ${lib.concatStringsSep "\n" (map (u: "sync_user ${u}") (builtins.attrNames cfg.users))}
        '';

      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
