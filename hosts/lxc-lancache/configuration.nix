{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.enable = true;

  age.secrets."lxc-lancache/steam-token-anna" = { };

  services.lancache = {
    enable = true;
    cacheLocation = "/lancache";

    prefill.steam = {
      enable = true;
      accounts.anna = {
        tokenFile = config.age.secrets."lxc-lancache/steam-token-anna".path;
        prefillAll = true;
        systems = [
          "windows"
          "linux"
        ];
      };
    };
  };

  lxc = {
    enable = true;
    memory = 4096;
    mounts = [
      "/storage/lancache,mp=/lancache"
    ];
  };

  system.stateVersion = "25.11";
}
