{
  config,
  pkgs,
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
    decky-loader = {
      enable = true;
      # TODO remove the following override
      package =
        (pkgs.decky-loader.override {
          pnpm_9 = pkgs.pnpm_10;
        }).overridePythonAttrs
          (old: {
            pnpmDeps = old.pnpmDeps.overrideAttrs {
              outputHash = "sha256-X1L8JYG5hgYMmfg0aa8XhkRU6/oFrYTPiXDIyq77puE=";
            };
          });
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
