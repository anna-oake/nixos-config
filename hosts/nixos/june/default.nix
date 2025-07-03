{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  services.iptsd.enable = true;

  boot = {
    secureboot.enable = true;
    kernelPackages = pkgs.linuxPackages_6_15;
  };

  users = {
    user = false;
    kiosk = true;
  };

  services.acpid.enable = true;
  services.logind.powerKey = "ignore";

  services.cage = {
    enable = true;
    user = "kiosk";
    program = "${pkgs.writeScriptBin "start-cage-app" ''
      #!/usr/bin/env bash
      ${pkgs.wlr-randr}/bin/wlr-randr --output DSI-1 --scale 1.5
      export MOZ_ENABLE_WAYLAND=1
      ${pkgs.firefox}/bin/firefox -kiosk https://h.koteeq.me
    ''}/bin/start-cage-app";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  system.stateVersion = "25.05";
}
