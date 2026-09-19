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
    hosts = [
      "eule"
      "gratis"
      "malina"
      "star"
      "lxc-builder"
      "lxc-docker"
      "lxc-lancache"
      "lxc-monitor"
      "lxc-net-router"
      "lxc-net-router-2"
      "lxc-phones"
      "lxc-proxy"
      "lxc-share"
      "lxc-slopster"
      "lxc-zrepl-mynah"
    ];
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
