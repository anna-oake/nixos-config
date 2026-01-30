{
  inputs,
  pkgs,
  hostName,
  config,
  ...
}:
{
  # common configuration for macOS machines

  environment.systemPath = [
    "/Users/anna/.local/bin"
  ];

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
  };

  launchd.daemons.nix-daemon.environment = {
    SSH_AUTH_SOCK = "/Users/anna/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  remoteBuilders = {
    protocol = "ssh";
    machines = {
      gratis = {
        enable = true;
        sshUser = "root";
      };
      lxc-builder-kitezh = {
        enable = true;
        sshUser = "root";
      };
    };
  };
}
