{
  inputs,
  pkgs,
  config,
  ...
}:
{
  age.secrets.user-password.file = (inputs.self + /secrets/user-password.age);

  users.mutableUsers = false;
  users.users.${config.me.username} = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [
      "wheel" # sudo
      "networkmanager" # network configuration
      "video"
    ];

    hashedPasswordFile = config.age.secrets.user-password.path;
    openssh.authorizedKeys.keys = config.me.sshKeys;
  };

  users.groups.users.gid = 100;
}
