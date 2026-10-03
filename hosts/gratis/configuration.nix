{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./hardware-configuration.nix
    ./users.nix
  ];

  profiles.server.enable = true;

  infra.deploy.fqdn = [ "gratis.oa.ke" ];

  monitoring.metrics.namePrefixes = lib.mkForce [ ];
  monitoring.metrics.smart = false;

  system.stateVersion = "25.11";
}
