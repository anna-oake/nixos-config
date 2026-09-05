{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.enable = true;

  age.secrets = {
    "lxc-builder/deploy-ssh-key" = { };
    "lxc-builder/deploy-attic-token" = { };
  };

  services.deployer = {
    enable = true;
    githubRepo = "anna-oake/nixos-config";
    hosts = [ "eule" ];
    atticServer = "attic.oa.ke";
    atticCache = "nixos";
    atticTokenFile = config.age.secrets."lxc-builder/deploy-attic-token".path;
    sshKeyFile = config.age.secrets."lxc-builder/deploy-ssh-key".path;
  };

  lxc = {
    enable = true;
    cores = 14;
    memory = 32768;
    diskSize = 100;
  };

  system.stateVersion = "25.11";
}
