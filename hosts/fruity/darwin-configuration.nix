{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.default
  ];

  profiles.server.enable = true;

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Do not remove
  system.stateVersion = 6;
}
