{
  config,
  lib,
  ...
}:
{
  nixpkgs.overlays = lib.mkAfter [
    (_: prev: {
      jovian-stubs = prev.jovian-stubs.overrideAttrs (old: {
        buildCommand = old.buildCommand + ''
          substituteInPlace $out/bin/steamos-polkit-helpers/steamos-update --replace-fail 'readlink /' 'readlink -f /'
        '';
      });
    })
  ];

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
    decky-loader = {
      enable = true;
      user = "gamer";
      stateDir = "/home/gamer/decky-loader";
    };
  };

  age.secrets."eule/gamer-password" = { };
  users.users.gamer = {
    isNormalUser = true;
    uid = 1001;
    group = "users";
    extraGroups = [
      "wheel"
      "networkmanager"
      "uinput"
      "netbird"
    ];
    hashedPasswordFile = config.age.secrets."eule/gamer-password".path;
    openssh.authorizedKeys.keys = [
      config.me.sshKey
    ];
  };
}
