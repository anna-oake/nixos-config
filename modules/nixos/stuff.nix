{
  pkgs,
  inputs,
  lib,
  flake,
  ...
}:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nix-things.nixosModules.default
    flake.commonModules.default
  ];

  users.me.enable = lib.mkDefault true;

  # boot
  boot.loader.timeout = 0;
  boot.splash = {
    enable = lib.mkDefault true;
    themePackage = pkgs.plymouth-feet-theme;
    theme = "feet";
  };

  # pkgs
  services.fwupd.enable = true;
  environment.systemPackages = with pkgs; [
    # shell
    wget
    p7zip
    usbutils
    pciutils
    go
  ];
}
