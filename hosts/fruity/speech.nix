{
  inputs,
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
}
