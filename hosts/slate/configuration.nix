{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./hardware-configuration.nix
    # ./face.nix
  ];

  profiles.workstation = {
    enable = true;
    gnome.enable = true;
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

  home-manager.backupFileExtension = ".bak";

  system.stateVersion = "26.05";
}
