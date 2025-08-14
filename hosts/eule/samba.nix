{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  mkShares =
    shares:
    lib.attrsets.mapAttrs (name: path: {
      "path" = path;
      "browseable" = "yes";
      "read only" = "no";
      "guest ok" = "no";
      "create mask" = "0644";
      "directory mask" = "0755";
      "veto files" = "/._*/.DS_Store/";
      "delete veto files" = "yes";
      "valid users" = "gamer";
    }) shares;
in
{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "server string" = "eule";
        "netbios name" = "eule";
        "access based share enum" = "yes";
        "fruit:encoding" = "native";
        "fruit:metadata" = "stream";
        "fruit:zero_file_id" = "yes";
        "fruit:nfs_aces" = "no";
        "vfs objects" = "catia fruit streams_xattr";
      };
    }
    // mkShares {
      "steam-games" = "/home/gamer/.local/share/Steam/steamapps/common";
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  age.secrets.gamer-samba-password.rekeyFile = "${flake}/secrets/gamer-samba-password.age";
  system.activationScripts.set-samba-password = ''
    smb_password=$(cat "${config.age.secrets.gamer-samba-password.path}")
    echo -e "$smb_password\n$smb_password\n" | ${lib.getExe' pkgs.samba "smbpasswd"} -a -s gamer
  '';
}
