{
  ...
}:
{
  mkBtrfsMount = part: subvol: {
    device = part;
    fsType = "btrfs";
    options = [
      "subvol=${subvol}"
      "compress=zstd"
      "noatime"
    ];
  };
}
