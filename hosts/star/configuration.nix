{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./hardware-configuration.nix
  ];

  profiles.server = {
    net-router = {
      enable = true;
      port = 51820;
      tokenType = "oake";
    };

    docker = {
      enable = true;
      portainer.enable = true;
    };
  };

  deploy.fqdn = "star.oa.ke";

  monitoring.machineType = "remote";

  # the server is shared with maeve
  users.users.root.openssh.authorizedKeys.keys = [
    config.me.wifeKey
  ];

  deploy.sshKeys = [
    config.me.deployKey
    config.me.wifeKey
  ];

  system.stateVersion = "25.11";
}
