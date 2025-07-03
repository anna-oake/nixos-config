{
  pkgs,
  inputs,
  lib,
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

  users.user = lib.mkDefault true;

  programs.chromium = {
    enable = true;
    extraOpts = {
	    "ExtensionManifestV2Availability" = 2;
    };
    extensions = [
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa"
    ];
  };

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
      (chromium.override { 
        enableWideVine = true; 
        commandLineArgs = [
          "--enable-features=AcceleratedVideoEncoder,VaapiVideoDecoder"
          "--ignore-gpu-blocklist"
          "--enable-zero-copy"
        ];
      })

      # shell
      wget
      p7zip
      usbutils
      pciutils
    ]
    ++ lib.optionals isAarch64 [
      legcord
      spotify-qt
    ]
    ++ lib.optionals isx86_64 [
      discord
      slack
      spotify
    ];
}
