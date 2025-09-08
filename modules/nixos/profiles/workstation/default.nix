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
  ];

  config = lib.mkIf config.profiles.workstation.enable {
    # boot
    boot.loader.timeout = 0;
    boot.splash = {
      enable = lib.mkDefault true;
      themePackage = pkgs.plymouth-feet-theme;
      theme = "feet";
    };

    # pkgs
    services.fwupd.enable = true;
    environment.systemPackages = with pkgs; [
      # shell
      wget
      p7zip
      usbutils
      pciutils
      go
      gh
      git
      htop
      btop
      nixfmt-rfc-style
      nixd
      fzf
      zoxide
    ];
  };
}
