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
        element-desktop
      ]
      ++ onlyX86 [
        spotify
        slack
        discord
      ]
      ++ onlyArm [
        legcord
      ];

    # Force-installed in Helium via Chromium policy (see the workstation profile).
    programs.chromium = {
      extensions = [
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
        "cdglnehniifkbagbbombnjghhcihifij" # Kagi
        "kpmjjdhbcfebfjgdnpjagcndoelnidfj" # Control Panel for Twitter
      ];
    };
  };
}
