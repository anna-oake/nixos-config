{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./netbird.nix
  ];

  profiles.server.zrepl = {
    enable = true;

    dataset = "storage/zrepl";

    pruningKeepSchedule = "1x1h(keep=all) | 24x1h | 30x1d | 3x30d";
    
    snapshotting = {
      datasets = [
        "rpool/storage/kalicraft<"
      ];
      cron = "0 * * * *"; # snapshots will be created on each hour
    };
    
    localJob = {
      datasets = [
        "rpool/storage/kalicraft<"
      ];
      interval = "30m"; # SSD -> HDD replication of new snapshots every 30 minutes
    };

    remoteJobs.pull = {
      mynah-buyan = {
        address = "zrepl-mynah-buyan.me.ow:28000";
        interval = "24h";
        bandwidthLimit = "10 Mb"; # bitch got dial up 😭
      };
    };
  };

  lxc = {
    enable = true;
  };

  system.stateVersion = "26.05";
}
