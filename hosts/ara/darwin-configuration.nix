{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.default
    ./wallpaper.nix
  ];

  profiles.workstation.enable = true;

  homebrew.casks = [ "kicad" ];
  environment.systemPackages = [ pkgs.konnect ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.linux-builder = {
    enable = true;

    systems = [
      "aarch64-linux"
    ];

    speedFactor = 10;

    ephemeral = false;

    config = {
      virtualisation = {
        cores = 10;
        darwin-builder = {
          memorySize = 12 * 1024;
          diskSize = 80 * 1024;
        };
      };
    };
  };

  # Do not remove
  system.stateVersion = 5;
}
