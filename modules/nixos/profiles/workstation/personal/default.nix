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

    # 1Password only talks to browsers it knows; Helium needs allowlisting by
    # binary name, and its native messaging host installed where Helium looks.
    environment.etc."1password/custom_allowed_browsers" = {
      text = "helium\n";
      mode = "0755";
    };
    environment.etc."chromium/native-messaging-hosts/com.1password.1password.json".text =
      builtins.toJSON
        {
          name = "com.1password.1password";
          description = "1Password BrowserSupport";
          path = "/run/wrappers/bin/1Password-BrowserSupport";
          type = "stdio";
          allowed_origins = [ "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/" ];
        };
  };
}
