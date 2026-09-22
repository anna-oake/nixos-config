{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    "${inputs.macos-speech-server}/nix/module.nix"
  ];

  services.speech-server = {
    enable = true;

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
}
