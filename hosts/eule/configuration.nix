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

  time.timeZone = "Europe/Amsterdam";

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

  security.rtkit.enable = true;
  services.pipewire.wireplumber.extraConfig."surround-by-default" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "alsa_output.pci-0000_03_00.1.hdmi-surround"; }
        ];
        actions.update-props = {
          "priority.driver" = 100;
          "priority.session" = 100;
        };
      }
    ];
  };

  system.stateVersion = "25.05";
}
