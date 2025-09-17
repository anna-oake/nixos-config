{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.default
    ./wallpaper.nix
  ];

  profiles.workstation.enable = true;

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Do not remove
  system.stateVersion = 5;
}
