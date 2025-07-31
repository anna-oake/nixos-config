{
  pkgs,
  flake,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    flake.nixosModules.default
  ];

  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.asahi.useExperimentalGPUDriver = true;

  boot.extraModprobeConfig = ''
    options hid_apple iso_layout=1
  '';

  boot.loader.grub.configurationLimit = 3;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # fix electron blur
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
    boot-macos
  ];

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  system.stateVersion = "25.11";
}
