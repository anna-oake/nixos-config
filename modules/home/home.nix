{
  inputs,
  ...
}:
{
  imports = [
    inputs.nix-things.homeModules.default
    inputs.niri.homeModules.config
  ];
}
