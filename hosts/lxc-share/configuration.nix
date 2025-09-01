{
  config,
  flake,
  ...
}:
{
  imports = [
    flake.lxcModules.default
    ./users.nix
    ./samba.nix
    ./sftp.nix
  ];

  share = {
    serverString = "Maeve Mynah";
    users = {
      maeve = {
        sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDvkX/XN4U6idAnpWO9JbFpKxJFsvGzfmSCCFKIMmpv";
      };
      anna = {
        sshKey = config.me.sshKey;
      };
    };
  };

  lxc.mounts = [
    "/storage,mp=/storage"
  ];

  system.stateVersion = "25.11";
}
