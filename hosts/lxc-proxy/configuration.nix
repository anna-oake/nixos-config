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
        proxy = "10.10.0.100:8889"; # ara.lan.al, but resolving is flaky
        port = 12345;
      }
    ];
  };

  # this allows 8192 connections
  systemd.services.redsocks.serviceConfig.LimitNOFILE = 65535;

  age.secrets."lxc-proxy/wireguard-priv" = { };

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.253.0.1/30" ];
    listenPort = 51820;

    privateKeyFile = config.age.secrets."lxc-proxy/wireguard-priv".path;

    peers = [
      {
        publicKey = "SAO+xdn6PNT1Pe8+jlUfA4rmrciB8bmUUqAYxHf4EXs=";
        allowedIPs = [ "10.253.0.2/32" ];
        persistentKeepalive = 25;
      }
    ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.wg0.route_localnet" = true;
  };

  # we'll route all connections through redsocks except ones destined for the lxc itself
  networking.nftables = {
    enable = true;
    tables.nat = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat
          iifname "wg0" ip protocol tcp dnat to 127.0.0.1:12345
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
