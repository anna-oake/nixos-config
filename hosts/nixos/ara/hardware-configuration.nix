{
  lib,
  inputs,
  ...
}:
let
  part = "/dev/nvme0n1p5";
  mkBtrfsMount = subvol: {
      device = part;
      fsType = "btrfs";
      options = [
        "subvol=${subvol}"
        "compress=zstd"
        "noatime"
      ];
  };
in
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
    inputs.apple-silicon-support.nixosModules.apple-silicon-support
  ];

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "usb_storage"
    "sdhci_pci"
  ];

  boot.kernelParams = [
    "apple_dcp.show_notch=1"
  ];

  fileSystems = {
    "/" = mkBtrfsMount "root";
    "/home" = mkBtrfsMount "home";
    "/nix" = mkBtrfsMount "nix";
    "/persist" = mkBtrfsMount "persist" // { neededForBoot = true; };
    "/var/log" = mkBtrfsMount "log" // { neededForBoot = true; };
  
    "/boot" = {
      device = "/dev/disk/by-uuid/3242-1D16";
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
    '';
  };

  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/var/lib/nixos"
      "/var/lib/tailscale"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  security.sudo.extraConfig = ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
