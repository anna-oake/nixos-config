{
  config,
  lib,
  pkgs,
  flake,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./gaming.nix
    flake.nixosModules.default
    inputs.jovian.nixosModules.default
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.desktopManager.plasma6.enable = true;

  system.stateVersion = "25.05";
}
