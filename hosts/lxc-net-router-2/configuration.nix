{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.lxcModules.default
  ];

  lxc.profiles.net-router = {
    enable = true;
    port = 30304;
  };

  system.stateVersion = "25.11";
}
