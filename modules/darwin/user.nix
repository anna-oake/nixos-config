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

  security.sudo.extraConfig = ''
    anna ALL=(root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild switch
  '';

  security.pam.services.sudo_local.touchIdAuth = true;
}
