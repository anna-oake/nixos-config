{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.default
    ./buildbot-user.nix
  ];

  profiles.server.enable = true;

  nixpkgs.hostPlatform = "aarch64-darwin";

  services.netbird.enable = true;

  # Do not remove
  system.stateVersion = 6;
}
