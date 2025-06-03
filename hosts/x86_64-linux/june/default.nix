{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.microsoft-surface-common
  ];

  hardware.microsoft-surface.kernelVersion = "stable";
  services.iptsd.enable = true;
  environment.systemPackages = with pkgs; [
    surface-control
    htop
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/London";

  users = {
    user = false;
    kiosk = true;
  };

  services.cage = {
    enable = true;
    user = "kiosk";
    program = "${pkgs.writeScriptBin "start-cage-app" ''
      #!/usr/bin/env bash
      ${pkgs.wlr-randr}/bin/wlr-randr --output DSI-1 --scale 1.5
      export MOZ_ENABLE_WAYLAND=1
      ${pkgs.firefox}/bin/firefox -kiosk https://h.koteeq.me
    ''}/bin/start-cage-app";
  };

  # # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # # Enable sound with pipewire.
  # services.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   # If you want to use JACK applications, uncomment this
  #   #jack.enable = true;

  #   # use the example session manager (no others are packaged yet so this is enabled by default,
  #   # no need to redefine it in your config for now)
  #   #media-session.enable = true;
  # };

  # # Enable touchpad support (enabled default in most desktopManager).
  # # services.xserver.libinput.enable = true;

  # # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.anna = {
  #   isNormalUser = true;
  #   description = "Anna Oake";
  #   extraGroups = [
  #     "networkmanager"
  #     "wheel"
  #   ];
  #   packages = with pkgs; [
  #     #  thunderbird
  #   ];
  # };

  # # Enable automatic login for the user.
  # services.displayManager.autoLogin.enable = true;
  # services.displayManager.autoLogin.user = "anna";

  # # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  # systemd.services."getty@tty1".enable = false;
  # systemd.services."autovt@tty1".enable = false;

  system.stateVersion = "25.05"; # Did you read the comment?

}
