{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./localisation.nix
    ./network.nix
    ./user.nix
    ./personal
  ];

  config = lib.mkIf config.profiles.workstation.enable {
    # boot
    boot.loader.timeout = 0;
    boot.splash = {
      enable = lib.mkDefault true;
      themePackage = pkgs.plymouth-feet-theme;
      theme = "feet";
    };

    environment.sessionVariables = lib.optionalAttrs (!config.hardware.nvidia.enabled) {
      NIXOS_OZONE_WL = "1"; # fix electron blur
    };

    # pkgs
    services.fwupd.enable = true;
    environment.systemPackages = with pkgs; [
      usbutils
      pciutils
    ];
  };
}
