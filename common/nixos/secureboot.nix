{
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  options.boot.secureboot.enable = lib.mkEnableOption "Secure Boot";

  config = lib.mkIf config.boot.secureboot.enable {
    boot.initrd.systemd.enable = true;
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.bootspec.enable = true;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
