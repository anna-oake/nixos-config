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
    memory = 30720;
    diskSize = 64;
  };

  system.stateVersion = "25.11";
}
