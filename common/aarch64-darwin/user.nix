{ pkgs, ... }:
{
  users.knownUsers = [ "anna" ];
  users.users.anna = {
    uid = 501;
  };
  system.primaryUser = "anna";

  security.pam.services.sudo_local.touchIdAuth = true;
}
