{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.enable {
    age.secrets."user-password" = { };

    users.users.anna = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "netbird"
      ];
      openssh.authorizedKeys.keys = [
        config.me.sshKey
      ];
    }
    // (
      if config.age.ready then
        {
          hashedPasswordFile = config.age.secrets.user-password.path;
        }
      else
        {
          hashedPassword = "$y$jFT$lTj/bGjovSblBCbRkgWV61$F1qpaiSf7L7BawAOW5tJ0RnAH2.zCTPTsWsMcayoI7A";
        }
    );
  };
}
