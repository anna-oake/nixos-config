{
  lib,
  ...
}:
{
  proxmoxLXC.manageNetwork = true;
  networking.hostName = lib.mkForce "";
}
