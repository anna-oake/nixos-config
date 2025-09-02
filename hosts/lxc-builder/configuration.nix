{
  flake,
  ...
}:
{
  imports = [
    flake.lxcModules.default
    ./buildbot.nix
    ./attic-watch.nix
  ];

  lxc = {
    cores = 10;
    memory = 32768;
    diskSize = 64;
  };

  system.stateVersion = "25.11";
}
