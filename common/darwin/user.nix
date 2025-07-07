{
  config,
  ...
}:
{
  users.knownUsers = [ config.me.username ];
  users.users.${config.me.username} = {
    uid = 501;
  };
  system.primaryUser = config.me.username;

  security.pam.services.sudo_local.touchIdAuth = true;
}
