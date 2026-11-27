{ inputs, pkgs, ... }:
{
  imports = [ inputs.nixun.nixosModules.redmi-pad-se ];

  nixpkgs.hostPlatform = "aarch64-linux";
  hardware.redmi-pad-se = {
    enable = true;
    touchscreenVariant = "novatek-nt36532";
  };

  systemd.services."systemd-backlight@backlight:5e94000.dsi.0" = {
    overrideStrategy = "asDropin";
    postStart = ''
      backlight=/sys/class/backlight/5e94000.dsi.0
      read -r maximum < "$backlight/max_brightness"
      printf '%s\n' "$(( (maximum + 1) / 2 ))" > "$backlight/brightness"
    '';
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_XUN";
    fsType = "ext4";
    autoResize = true;
  };

  environment.systemPackages = [ pkgs.qbootctl ];
}
