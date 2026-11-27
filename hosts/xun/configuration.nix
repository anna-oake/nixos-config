{ inputs, ... }:
{
  imports = [
    inputs.self.nixosModules.default
    ./hardware-configuration.nix
    ./peripherals.nix
    ./wifi.nix
  ];

  profiles.server.enable = true;

  infra.deploy.fqdn = [ "iot-xun.lan.al" ];

  system.stateVersion = "26.11";
}
