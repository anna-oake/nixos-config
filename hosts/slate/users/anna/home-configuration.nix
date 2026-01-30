{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.homeModules.default
  ];

  profiles.workstation.enable = true;

  home.stateVersion = "26.05";
}
