{
  config,
  lib,
  pkgs,
  ...
}:
let
  # server
  mkShares =
    shares:
    lib.attrsets.mapAttrs (_: path: {
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

  # client
  mkMynahMounts =
    mounts:
    lib.attrsets.mapAttrs (_: share: {
      device = "//share.lan.al/${share}";
      fsType = "cifs";
      options = [
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60min"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "soft"
        "uid=${toString config.users.users.gamer.uid}"
        "gid=${toString config.users.groups.users.gid}"
        "credentials=${config.age.secrets."eule/mynah-smb".path}"
      ];
    }) mounts;
in
{
  # server
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

  age.secrets."eule/gamer-samba-password" = { };
  system.activationScripts.set-samba-password = ''
    smb_password=$(cat "${config.age.secrets."eule/gamer-samba-password".path}")
    echo -e "$smb_password\n$smb_password\n" | ${lib.getExe' pkgs.samba "smbpasswd"} -a -s gamer
  '';

  # client
  environment.systemPackages = with pkgs; [
    cifs-utils
  ];
  age.secrets."eule/mynah-smb" = { };
  fileSystems = mkMynahMounts {
    "/mnt/mynah/family" = "family";
  };
}
