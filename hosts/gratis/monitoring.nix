{
  config,
  lib,
  ...
}:
{
  monitoring.machineType = "remote";
  monitoring.metrics.namePrefixes = lib.mkForce [ ];
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
