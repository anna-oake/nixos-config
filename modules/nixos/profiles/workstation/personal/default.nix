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
        chromium
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

    programs.chromium = {
      enable = true;
      extensions = [
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
        "cdglnehniifkbagbbombnjghhcihifij" # Kagi
        "kpmjjdhbcfebfjgdnpjagcndoelnidfj" # Control Panel for Twitter
      ];
    };

    age.secrets.gh-miaow-linux = {
      owner = config.me.username;
    };

    nix.extraOptions = ''
      !include ${config.age.secrets.gh-miaow-linux.path}
    '';
  };
}
