{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-things.nixosModules.default
    inputs.self.commonModules.default
  ];

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
  ];
}
