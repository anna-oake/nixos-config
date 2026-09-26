{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./hardware-configuration.nix
    ./users.nix
    ./monitoring.nix
  ];

  profiles.server.enable = true;

  infra.deploy.fqdn = "gratis.oa.ke";

  system.stateVersion = "25.11";
}
