{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./hardware-configuration.nix
  ];

  profiles.server.net-router = {
    enable = true;
    port = 30303;
    tokenType = "cloud";
  };

  deploy.fqdn = "ru.koteeq.me";

  system.stateVersion = "25.11";
}
