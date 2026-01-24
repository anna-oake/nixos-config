{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./vm.nix
    inputs.self.nixosModules.default
  ];

  profiles.workstation.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # fix electron blur
  };

  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    btrfs-progs
    libimobiledevice
    ifuse
  ];

  services.usbmuxd.enable = true;

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  system.stateVersion = "26.05";
}
