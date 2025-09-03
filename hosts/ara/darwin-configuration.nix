{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.default
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Do not remove
  system.stateVersion = 5;
}
