{ pkgs, ... }:
{
  users.knownUsers = [ "anna" ];
  users.users.anna = {
    uid = 501;
  };

  security.pam.enableSudoTouchIdAuth = true;
}
