{
  inputs,
  pkgs,
  hostName,
  config,
  ...
}:
{
  # common configuration for macOS machines

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.self.commonModules.default
  ];

  macos-layouts = {
    enable = true;
    packages = with pkgs; [
      ilya-birman-typography-layout
    ];
  };

  # networking
  networking.computerName = hostName;

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

  environment.systemPackages = with pkgs; [
    gh
    git
    htop
    btop
    nixfmt-rfc-style
    nixd
    fzf
    zoxide
  ];
}
