{
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isAarch64 isx86_64;
in
{
  imports = [
    ./1password.nix
    ./localisation.nix
    ./network.nix
    ./secureboot.nix
    ./splash.nix
    ./user.nix
    inputs.nix-index-database.nixosModules.nix-index
  ];

  # boot
  boot.loader.timeout = 0;

  # pkgs
  services.fwupd.enable = true;

  programs.direnv.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      # dev
      (vscode-with-extensions.override {
        vscodeExtensions =
          with vscode-marketplace;
          with vscode-extensions;
          [
            jnoortheen.nix-ide
            ms-vsliveshare.vsliveshare
            esphome.esphome-vscode
            mkhl.direnv
          ];
      })

      # apps
      telegram-desktop
      element-desktop

      # shell
      wget
      p7zip
      usbutils
      pciutils

      chromium
    ]
    ++ lib.optionals isAarch64 [
      legcord
    ]
    ++ lib.optionals isx86_64 [
      discord
    ];
}
