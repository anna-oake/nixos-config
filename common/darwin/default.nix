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
    ./macos-layouts.nix
    ./network.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  macos-layouts = {
    enable = true;
    packages = with pkgs; [
      ilya-birman-typography-layout
    ];
  };

  # networking
  networking.computerName = hostname;

  # homebrew
  nix-homebrew = {
    user = config.me.username;
    enable = true;

    taps = with inputs; {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
    };

    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    taps = builtins.attrNames config.nix-homebrew.taps;

    casks = [
      # dev
      "visual-studio-code"

      # apps
      "telegram"
    ];
  };
}
