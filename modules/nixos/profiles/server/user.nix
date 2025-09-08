{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.server.enable {
    users.users.root.openssh.authorizedKeys.keys = [
      config.me.sshKey
    ];

    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
  };
}
