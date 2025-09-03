{
  lib,
  config,
  ...
}:
{
  options.lxc.profiles.net-router = {
    enable = lib.mkEnableOption "net-router profile";
    port = lib.mkOption {
      type = lib.types.port;
      example = lib.literalExpression "51820";
      description = ''
        Port the NetBird client listens on.
      '';
    };
  };

  config = lib.mkIf config.lxc.profiles.net-router.enable {
    age.secrets.netbird-homelab = {
      owner = "netbird";
      group = "netbird";
    };

    services.netbird.simple = {
      enable = true;
      managementUrl = "https://net.oa.ke";
      setupKeyFile = config.age.secrets.netbird-homelab.path;
    };

    services.netbird.clients.default.port = lib.mkForce config.lxc.profiles.net-router.port;

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    services.iperf3.enable = true;
  };
}
