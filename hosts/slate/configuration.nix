{
  inputs,
  pkgs,
  ...
}:
let
  miaow = inputs.miaow.packages.x86_64-linux.default;
in
{
  imports = [
    inputs.self.nixosModules.default
    ./hardware-configuration.nix
    # ./face.nix
  ];

  profiles.workstation = {
    enable = true;
    gnome = {
      enable = true;
      dockItems.middle = [ "ke.oa.miaow.desktop" ];
      shellExtensions =
        (with pkgs.gnomeExtensions; [
          user-themes
          just-perfection
          appindicator
        ])
        ++ [ miaow ];
    };
    laptop.enable = true;
    wifi.enable = true;
  };

  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse
    quicktime-video-hack
  ];

  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };

  services.fprintd = {
    enable = true;
    cs9711 = true;
  };

  home-manager.backupFileExtension = ".bak";

  system.stateVersion = "26.05";
}
