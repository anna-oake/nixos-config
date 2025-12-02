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

  age.secrets."lxc-lancache/steam-anya-token" = { };

  services.lancache = {
    enable = true;
    cacheLocation = "/lancache";

    prefill.steam = {
      enable = true;
      accounts.anna = {
        tokenFile = config.age.secrets."lxc-lancache/steam-anya-token".path;
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
    mounts = [
      "/storage/lancache,mp=/lancache"
    ];
  };

  system.stateVersion = "25.11";
}
