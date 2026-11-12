{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./gaming.nix
    ./decky-plugins.nix
    ./samba.nix
    ./led.nix
    inputs.self.nixosModules.default
    inputs.jovian.nixosModules.default
  ];

  profiles.workstation = {
    enable = true;
    personal.enable = false;
  };

  # hdmi 2.1!!!!

  boot.kernelPackages = pkgs.linuxPackages_testing;

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
    linkwinbt
  ];

  hardware.amdgpu.opencl.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.desktopManager.plasma6.enable = true;

  security.rtkit.enable = true;
  services.pipewire-denon = {
    enable = true;
    user = "gamer";
    targetNode = "alsa_output.pci-0000_03_00.1.hdmi-surround-extra3";
    host = "iot-avr.lan.al";
  };

  services.pipewire.wireplumber.extraConfig = {
    # auto select the 5.1 surround sound profile AND disable restoring user selected profile
    "99-surround-by-default" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "device.name" = "alsa_card.pci-0000_03_00.1"; }
          ];
          actions.update-props = {
            "device.profile" = "output:hdmi-surround-extra3";
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

  # drkonqi is freaky, it keeps crashing and trying to report on itself and crashing over and over and over and over and over
  systemd.services."drkonqi-coredump-processor@".enable = false;

  programs.steam = {
    extest.enable = true;
    protontricks.enable = true;
  };
  services.steam-lancache-beacon = {
    enable = true;
    baseUrl = "https://lancache.lan.al";
    user = "gamer";
  };
  hardware.uinput.enable = true;

  home-manager.backupFileExtension = ".bak";

  monitoring = {
    logs.system.enable = true;
    metrics.enable = true;
    metrics.gpu = "amd";
  };

  services.eule-rebooter.enable = true;

  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-id/nvme-KINGSTON_SNV3S2000G_50026B7785BA74DD-part2";
    fsType = "ntfs";
    options = [
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=10s"
      "uid=0"
      "gid=${toString config.users.groups.users.gid}"
      "umask=002"
    ];
  };

  infra.deploy.auto = true;

  system.stateVersion = "25.05";
}
