{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.homeModules.default
  ];

  profiles.workstation.enable = true;

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
