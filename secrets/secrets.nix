let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHf6UCNeXSN8WAZ9cXh8jz61+jbP+ts+inct/CCjcN/o";
  june = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFUV/VR3syeQplSZcUiBbe1QG4E0C36kWzlhJYMbWEQ";
  ara-nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaXGEBuUUsviWKNUGc4qnSxMCN0jfausbqZ7whFr2jS";
  hosts = [
    june
    ara-nixos
  ];
  all = [ user ] ++ hosts;
in
{
  "user-password.age".publicKeys = all;
  "kiosk-password.age".publicKeys = all;

  "attic-netrc.age".publicKeys = all;

  # wifi
  "wifi-home.age".publicKeys = all;
}
