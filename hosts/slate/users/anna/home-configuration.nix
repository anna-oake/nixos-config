{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.homeModules.default
  ];

  profiles.workstation = {
    enable = true;
    niri.enable = true;
  };

  home.stateVersion = "26.05";
}
