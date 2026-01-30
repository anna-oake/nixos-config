{
  config,
  lib,
  pkgs,
  onlyX86,
  onlyArm,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.personal.enable {
    environment.systemPackages =
      with pkgs;
      [
        httpie-desktop
        telegram-desktop
        github-desktop
        charles
      ]
      ++ onlyX86 [
        spotify
        slack
        discord
      ]
      ++ onlyArm [
        legcord
      ];
  };
}
