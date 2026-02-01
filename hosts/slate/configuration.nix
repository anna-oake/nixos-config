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
  ];

  home-manager.backupFileExtension = ".bak";

  services.usbmuxd.enable = true;

  system.stateVersion = "26.05";
}
