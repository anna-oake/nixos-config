{
  config,
  flake,
  ...
}:
{
  jovian = {
    hardware = {
      has.amd.gpu = true;
      amd.gpu.enableBacklightControl = false;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "gamer";
      desktopSession = "plasma";
    };
  };

  age.secrets.gamer-password.rekeyFile = "${flake}/secrets/gamer-password.age";
  users.users.gamer = {
    isNormalUser = true;
    uid = 1001;
    group = "users";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    hashedPasswordFile = config.age.secrets.gamer-password.path;
    openssh.authorizedKeys.keys = [
      config.me.sshKey
    ];
  };
}
