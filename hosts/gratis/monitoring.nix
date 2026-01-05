{
  config,
  ...
}:
{
  monitoring.machineType = "remote";
  age.secrets.netbird-monitor = {
    owner = "netbird";
    group = "netbird";
  };

  services.netbird.simple = {
    enable = true;
    managementUrl = "https://net.oa.ke";
    setupKeyFile = config.age.secrets.netbird-monitor.path;
  };
}
