{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.enable = true;

  lxc = {
    enable = true;
    cores = 14;
    memory = 32768;
    diskSize = 100;
  };

  system.stateVersion = "25.11";
}
