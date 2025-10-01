{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.share = {
    enable = true;
    serverString = "Anna Mynah";
    users = {
      anna = {
        uid = 1001;
        sshKeys = [
          config.me.sshKey
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+jz3sPX+PhQrpiVxdW/YVhZW2y+KrSnR8lsQAB3d+j opnsense"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHS4UB8RMgcb6A5RqBCu1+wrSPvwKW4lGADo0RBpk9xL arq"
        ];
        allowedExtraShares = [
          "family"
          "oake"
          "media"
        ];
      };
      maeve = {
        uid = 1004;
        sshKey = config.me.wifeKey;
        allowedExtraShares = [
          "oake"
          "media"
        ];
      };
      alina = {
        uid = 1000;
        allowedExtraShares = [
          "family"
          "media"
        ];
      };
      eule = {
        uid = 1003;
        allowedExtraShares = [
          "family"
        ];
      };
    };
    extraShares = {
      "family" = "/storage/share/family";
      "oake" = "/storage/share/oake";
      "media" = "/storage/media";
    };
  };

  lxc = {
    enable = true;
    mounts = [
      "/storage,mp=/storage"
    ];
  };

  # Arq Backup can't connect otherwise
  services.openssh.settings.Macs = lib.mkOptionDefault [
    "hmac-sha2-512"
  ];

  system.stateVersion = "25.11";
}
