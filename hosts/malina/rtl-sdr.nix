{ pkgs, ... }:
{
  hardware.rtl-sdr = {
    enable = true;
    package = pkgs.rtl-sdr-blog;
  };

  users = {
    groups.rtl-tcp = { };
    users.rtl-tcp = {
      isSystemUser = true;
      group = "rtl-tcp";
      extraGroups = [ "plugdev" ];
    };
  };

  systemd.services.rtl-tcp = {
    description = "RTL-SDR TCP server";
    documentation = [ "https://github.com/rtlsdrblog/rtl-sdr-blog" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "systemd-udevd.service"
    ];

    serviceConfig = {
      User = "rtl-tcp";
      Group = "rtl-tcp";
      ExecStart = "${pkgs.rtl-sdr-blog}/bin/rtl_tcp -a 0.0.0.0 -p 1234 -T";
      Restart = "always";
      RestartSec = "2s";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
    };
  };
}
