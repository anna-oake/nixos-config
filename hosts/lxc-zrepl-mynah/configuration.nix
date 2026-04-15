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

    remoteJobs.pull = {
      mynah-buyan = {
        address = "zrepl-mynah-buyan.me.ow:28000";
        interval = "manual";
        bandwidthLimit = "10 Mb"; # bitch got dial up 😭
      };
    };
  };

  lxc = {
    enable = true;
  };

  system.stateVersion = "26.05";
}
