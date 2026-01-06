{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./gaming.nix
    ./samba.nix
    inputs.self.nixosModules.default
    inputs.jovian.nixosModules.default
  ];

  profiles.workstation.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Europe/Amsterdam";

  boot.loader = {
    efi.canTouchEfiVariables = lib.mkOverride 5 false; # priority 5 or disko fucks this up
    grub = {
      enable = true;
      useOSProber = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      devices = lib.mkOverride 5 [ "nodev" ]; # priority 5 or disko fucks this up
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
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.desktopManager.plasma6.enable = true;
  services.orca.enable = false; # failing to build otherwise

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

  programs.steam = {
    extest.enable = true;
    protontricks.enable = true;
  };
  hardware.uinput.enable = true;

  home-manager.backupFileExtension = ".bak";

  monitoring.logs.enable = true;

  system.stateVersion = "25.05";
}
