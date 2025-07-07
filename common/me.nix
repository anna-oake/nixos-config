{
  lib,
  ...
}:
{
  options.me = {
    username = lib.mkOption { type = lib.types.str; };
    email = lib.mkOption { type = lib.types.str; };
    sshKey = lib.mkOption { type = lib.types.str; };
  };

  config.me = {
    username = "anna";
    email = "anna@oa.ke";
    sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHf6UCNeXSN8WAZ9cXh8jz61+jbP+ts+inct/CCjcN/o anna@oa.ke";
  };
}
