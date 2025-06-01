{
  pkgs,
  inputs,
  system,
  ...
}:
{
  # common configuration for x86_64 Linux machines

  imports = [
    ./localisation.nix
    ./network.nix
    ./user.nix
    # inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # boot
  boot.loader.timeout = 0;

  # pkgs
  services.fwupd.enable = true;
  environment.systemPackages = with pkgs; [
    git
  ];
}
