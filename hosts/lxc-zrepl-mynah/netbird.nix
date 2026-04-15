{
  config,
  lib,
  ...
}:
{
  age.secrets.netbird-homelab = {
    owner = "netbird";
    group = "netbird";
  };

  services.netbird.simple = {
    enable = true;
    managementUrl = "https://net.oa.ke";
    setupKeyFile = config.age.secrets.netbird-homelab.path;
  };

  services.netbird.clients.default.port = lib.mkForce 31314;
}
