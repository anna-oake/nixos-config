{
  flake,
  ...
}:
{
  imports = [
    flake.lxcModules.default
  ];

  system.stateVersion = "25.11";
}
