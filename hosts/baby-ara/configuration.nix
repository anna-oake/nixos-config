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
    personal.enable = true;
    gnome.enable = true;
  };

  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse
  ];

  services.usbmuxd.enable = true;

  home-manager.backupFileExtension = ".bak";

  system.stateVersion = "26.05";
}
