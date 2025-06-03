{
  lib,
  inputs,
  config,
  ...
}:
let
  cfg = config.boot.secureboot;
in
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  options = {
    boot.secureboot.enable = lib.mkEnableOption "secure boot";
  };

  config = lib.mkIf cfg.enable {
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
