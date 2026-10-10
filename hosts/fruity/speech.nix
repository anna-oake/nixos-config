{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    "${inputs.macos-speech-server}/nix/module.nix"
  ];

  services.speech-server = {
    enable = true;
    package = pkgs.speech-server.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./patches/wyoming-close-on-eof.patch ];
    });

    settings = {
      servers = {
        http.host = "0.0.0.0";
        wyoming.host = "0.0.0.0";
      };
      tts.engine = "avspeech";
    };
  };

  launchd.daemons.speech-server.serviceConfig.ProgramArguments = lib.mkForce [
    "/bin/sh"
    "-c"
    "/bin/wait4path /nix/store && exec ${lib.getExe config.services.speech-server.package} serve"
  ];

  # KeepAlive cannot recover a process that stays alive but stops serving HA.
  launchd.daemons.speech-server-health.serviceConfig = {
    ProgramArguments = [
      (lib.getExe pkgs.python3)
      (toString ./speech-health.py)
    ];
    StartInterval = 60;
    RunAtLoad = true;
    StandardOutPath = "/var/log/speech-server/health.log";
    StandardErrorPath = "/var/log/speech-server/health.log";
  };
}
