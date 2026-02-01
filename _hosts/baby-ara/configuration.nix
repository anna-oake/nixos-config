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

  profiles.workstation = {
    enable = true;
    personal.enable = false;
  };

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
