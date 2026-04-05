{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.self.homeModules.default
  ];

  profiles.workstation.enable = true;

  home.packages = with pkgs; [
    docker
    docker-compose
    docker-buildx
    docker-credential-helpers
  ];

  programs.docker-cli = {
    enable = true;
    settings = {
      credsStore = "osxkeychain";
    };
  };

  home.file."${config.programs.docker-cli.configDir}/cli-plugins/docker-buildx".source =
    "${pkgs.docker-buildx}/bin/docker-buildx";
  home.file."${config.programs.docker-cli.configDir}/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/bin/docker-compose";

  programs.lazydocker.enable = true;

  services.colima = {
    enable = true;

    profiles.default = {
      isService = true;
      isActive = true;

      settings = {
        runtime = "docker";
        arch = "host";

        vmType = "vz";
        mountType = "virtiofs";
        mounts = [ ];

        cpu = 4;
        memory = 8;
        disk = 100;

        kubernetes.enabled = false;

        portForwarder = "ssh";
      };
    };
  };

  programs.hammerspoon = {
    enable = true;
    scripts = {
      fix-audio-input = {
        enable = true;
        settings = {
          badInputs = [
            "AirPods"
            "OpenRun"
          ];
          goodInputs = [
            "Shure MV7"
            "MacBook Pro Microphone"
          ];
        };
      };
    };
  };

  home.stateVersion = "25.11";
}
