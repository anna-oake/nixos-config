{
  config,
  ...
}:
{
  users.knownUsers = [ config.me.username ];
  users.users.${config.me.username} = {
    uid = 501;
    home = "/Users/${config.me.username}";
  };
  system.primaryUser = config.me.username;

  security.pam.services.sudo_local.touchIdAuth = true;

  nix.settings.trusted-users = [ config.me.username ];
}
