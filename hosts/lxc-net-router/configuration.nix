{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.self.lxcModules.default
  ];

  lxc.network = "vmbr1";
  lxc.pve.host = "kolibri." + config.me.lanDomain;

  lxc.profiles.net-router = {
    enable = true;
    port = 30303;
  };

  system.stateVersion = "25.11";
}
