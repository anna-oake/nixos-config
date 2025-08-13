{
  config,
  lib,
  inputs,
  flake,
  pkgs,
  ...
}:
let
  part = "/dev/disk/by-uuid/1081f64d-847e-43ac-b88f-f6d7baa6bf8c";
  mkBtrfsMount = flake.lib.mkBtrfsMount part;
in
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "ahci"
    "usbhid"
    "uas"
  ];
  boot.kernelModules = [
    "kvm-amd"
  ];

  hardware.firmware = [
    pkgs.rtl8761bu-firmware
  ];

  services.udev.extraRules = ''
    # Allow this Realtek BT dongle to wake the system
    ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="a729", \
      ATTR{power/wakeup}="enabled"
  '';

  networking.interfaces.enp14s0.wakeOnLan.enable = true;

  fileSystems = {
    "/" = mkBtrfsMount "root";
    "/home" = mkBtrfsMount "home";
    "/nix" = mkBtrfsMount "nix";
    "/persist" = mkBtrfsMount "persist" // {
      neededForBoot = true;
    };
    "/var/log" = mkBtrfsMount "log" // {
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/12CE-A600";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  boot.initrd = {
    enable = true;
    supportedFilesystems = [ "btrfs" ];

    postResumeCommands = lib.mkAfter ''
      (
        set -euo pipefail

        udevadm settle || true
        for i in $(seq 1 60); do
          if [ -b "${part}" ]; then break; fi
          echo "[impermanence] waiting for ${part} ($i/60)…"
          sleep 0.5
          udevadm settle || true
        done

        mkdir -p /btrfs
        mount -o subvol=/ ${part} /btrfs

        btrfs subvolume list -o /btrfs/root |
        cut -f9 -d' ' |
        while read subvolume; do
          echo "deleting /$subvolume subvolume..."
          btrfs subvolume delete "/btrfs/$subvolume"
        done &&
        echo "deleting /root subvolume..." &&
        btrfs subvolume delete /btrfs/root

        echo "restoring blank /root subvolume..."
        btrfs subvolume snapshot /btrfs/root-blank /btrfs/root

        umount /btrfs
      ) || echo "[impermanence] wipe failed — continuing boot."
    '';
  };

  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/var/lib/nixos"
      "/var/lib/bluetooth"
      "/root"
      "/var/lib/netbird"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/var/lib/plymouth/boot-duration"
    ];
  };

  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  security.sudo.extraConfig = ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
