{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isx86_64;
in
{
  options.profiles.workstation.laptop.enable = lib.mkEnableOption "Laptop workstation profile";

  config = lib.mkIf config.profiles.workstation.laptop.enable {
    profiles.workstation.enable = lib.mkForce true;

    systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkIf isx86_64 "4h";
    services.logind.settings.Login.HandleLidSwitch = lib.mkIf isx86_64 "suspend-then-hibernate";
  };
}
