{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.monitor.enable = true;

  profiles.server.net-router = {
    enable = true;
    port = 30305;
    enableForwarding = false;
    tokenType = "monitor";
  };

  # funny right?
  monitoring.logs.systemd.enable = false;

  lxc = {
    enable = true;
    memory = 8192;
    mounts = [
      "lxc:monitor-storage,mp=/storage,backup=1,size=100G"
    ];
    network = "vmbr1"; # important! this is deployed to a router where vmbr0 is WAN
    pve.host = "kolibri." + config.me.lanDomain;
  };

  system.stateVersion = "25.11";
}
