{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./disk.nix
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

  boot.initrd = {
    enable = true;
    supportedFilesystems = [ "btrfs" ];
  };

  environment.persistence."/persist" = {
    directories = [
      {
        directory = "/etc/nixos";
        user = config.me.username;
        group = "users";
      }
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
