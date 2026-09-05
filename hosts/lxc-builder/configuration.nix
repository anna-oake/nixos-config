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

  age.secrets."lxc-builder/deploy-ssh-key" = { };

  services.deployer = {
    enable = true;
    githubRepo = "anna-oake/nixos-config";
    hosts = [ "eule" ];
    atticServer = "attic.oa.ke";
    atticCache = "nixos";
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
