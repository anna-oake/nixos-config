{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./hardware-configuration.nix
    ./power.nix
    # ./face.nix
  ];

  profiles.workstation = {
    enable = true;
    niri.enable = true;
    laptop.enable = true;
    wifi.enable = true;
  };

  services.fprintd = {
    enable = true;
    cs9711 = true;
  };

  home-manager.backupFileExtension = ".bak";
  home-manager.overwriteBackup = true;

  system.stateVersion = "26.05";
}
