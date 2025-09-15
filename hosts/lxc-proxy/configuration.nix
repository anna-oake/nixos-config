{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.enable = true;

  services.redsocks = {
    enable = true;
    redsocks = [
      {
        type = "socks5";
        proxy = "10.10.0.100:8889"; # anya-mac.lan.al, but resolving is flaky
        port = 12345;
      }
    ];
  };

  # this allows 8192 connections
  systemd.services.redsocks.serviceConfig.LimitNOFILE = 65535;

  # we need this because we're routing external traffic
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.all.route_localnet" = true;
  };

  # we'll route all connections through redsocks except ones destined for the lxc itself
  networking.nftables = {
    enable = true;
    tables.nat = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat
          fib daddr type local return
          meta l4proto tcp dnat to 127.0.0.1:12345
        }
        chain postrouting {
          type nat hook postrouting priority srcnat
        }
      '';
    };
  };

  lxc = {
    enable = true;
    network = "vmbr1"; # important! this is deployed to a router where vmbr0 is WAN
    pve.host = "kolibri." + config.me.lanDomain;
  };

  system.stateVersion = "25.11";
}
