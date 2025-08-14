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
    ./samba.nix
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
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-vaapi
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.desktopManager.plasma6.enable = true;

  security.rtkit.enable = true;
  services.pipewire.wireplumber.extraConfig = {
    # auto select the 5.1 surround sound profile AND disable restoring user selected profile
    "99-surround-by-default" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "device.name" = "alsa_card.pci-0000_03_00.1"; }
          ];
          actions.update-props = {
            "device.profile" = "output:hdmi-surround";
          };
        }
      ];

      "wireplumber.settings" = {
        "device.restore-profile" = false;
      };
    };
    # fix audio falling asleep
    "99-disable-suspend"."monitor.alsa.rules" = [
      {
        matches = [
          {
            "node.name" = "~alsa_input.*";
          }
          {
            "node.name" = "~alsa_output.*";
          }
        ];
        actions.update-props = {
          "session.suspend-timeout-seconds" = 0;
          "node.always-process" = true;
          "dither.method" = "wannamaker3";
          "dither.noise" = 1;
        };
      }
    ];
  };

  programs.steam.extest.enable = true;
  hardware.uinput.enable = true;

  home-manager.backupFileExtension = ".bak";

  system.stateVersion = "25.05";
}
