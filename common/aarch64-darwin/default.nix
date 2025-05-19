{
  pkgs,
  hostname,
  inputs,
  config,
  ...
}:
{
  # common configuration for macOS machines
  imports = [
    ./user.nix
    ./system-defaults.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  # networking
  networking.computerName = hostname;

  # homebrew
  nix-homebrew = {
    user = "anna";
    enable = true;

    taps = with inputs; {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
    };

    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    taps = builtins.attrNames config.nix-homebrew.taps;

    casks = [
      # dev
      "visual-studio-code"

      # apps
      "telegram"

      # system
      "ilya-birman-typography-layout"
    ];
  };

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
}
