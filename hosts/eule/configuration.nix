{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    flake.nixosModules.default
  ];

  boot.loader = {
    grub = {
      enable = true;
      useOSProber = true;
      efiSupport = true;
      device = "nodev";
      extraConfig = ''
        menuentry_id_option="--id"
        export menuentry_id_option

        insmod net
        insmod efinet
        insmod tftp

        net_bootp

        source (tftp,eule-booter.lan.al)
      '';

      extraEntries = ''
        menuentry "UEFI Firmware Settings" --id "uefi-firmware" {
          fwsetup
        }
      '';
    };
    efi.canTouchEfiVariables = true;
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];

  system.stateVersion = "25.05";
}
