let
  user = (import ../me.nix).me.sshKeys;
  june = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFUV/VR3syeQplSZcUiBbe1QG4E0C36kWzlhJYMbWEQ";
  hosts = [
    june
  ];
  all = user ++ hosts;
in
{
  "user-password.age".publicKeys = all;
  "attic-netrc.age".publicKeys = all;

  # wifi
  "wifi-home.age".publicKeys = all;
  "wifi-temp.age".publicKeys = all;
}
