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
  };
}
