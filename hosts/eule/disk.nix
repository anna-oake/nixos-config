{
  inputs,
  lib,
  ...
}:
let
  # fucking around:
  device = "/dev/disk/by-id/usb-KIOXIA_EXCERIA_PLUS_635FC19CFPH4-0:0";
  # production:
  # device = "/dev/disk/by-id/nvme-KINGSTON_SNV3S2000G_50026B73834AB709";
  rootPart = device + "-part2";
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  fileSystems = {
    "/persist".neededForBoot = true;
    "/var/log".neededForBoot = true;
  };

  boot.initrd.postResumeCommands = lib.mkAfter ''
    (
      set -euo pipefail

      udevadm settle || true
      for i in $(seq 1 60); do
        if [ -b "${rootPart}" ]; then break; fi
        echo "[impermanence] waiting for ${rootPart} ($i/60)…"
        sleep 0.5
        udevadm settle || true
      done

      mkdir -p /btrfs
      mount -o subvol=/ ${rootPart} /btrfs

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

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "550M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0022"
                  "dmask=0022"
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                postCreateHook = ''
                  MNTPOINT=$(mktemp -d)
                  mount ${rootPart} "$MNTPOINT" -o subvol=/
                  trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                  btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
                '';
                subvolumes =
                  (lib.attrsets.mapAttrs (
                    name: mountpoint: {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      inherit mountpoint;
                    }
                  ))
                    {
                      "root" = "/";
                      "home" = "/home";
                      "nix" = "/nix";
                      "persist" = "/persist";
                      "log" = "/var/log";
                    };
              };
            };
          };
        };
      };
    };
  };
}
