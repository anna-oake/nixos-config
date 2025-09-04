{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.self.lxcModules.default
  ];

  lxc.profiles.share = {
    enable = true;
    serverString = "Anna Mynah";
    users = {
      anna = {
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
        sshKey = config.me.wifeKey;
        allowedExtraShares = [
          "oake"
          "media"
        ];
      };
      alina = {
        allowedExtraShares = [
          "family"
          "media"
        ];
      };
      eule = {
        allowedExtraShares = [
          "family"
        ];
      };
      bazzite = {
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

  lxc.mounts = [
    "/storage,mp=/storage"
  ];

  system.stateVersion = "25.11";
}
