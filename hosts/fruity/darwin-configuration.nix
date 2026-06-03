{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.default
    ./buildbot-user.nix
    ./speech.nix
  ];

  profiles.server.enable = true;

  nixpkgs.hostPlatform = "aarch64-darwin";

  services.netbird.enable = true;

  homebrew.masApps = {
    "Xcode" = 497799835;
  };

  # Do not remove
  system.stateVersion = 6;
}
