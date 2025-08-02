{
  pkgs,
  osConfig,
  inputs,
  ...
}:
{
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    workspace = {
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
    };
  };

  home.stateVersion = "25.11";
}
