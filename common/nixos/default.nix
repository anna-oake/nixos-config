{
  pkgs,
  inputs,
  lib,
  onlyArm,
  onlyX86,
  ...
}:
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
          "--enable-features=AcceleratedVideoEncoder,VaapiVideoDecoder,TouchpadOverscrollHistoryNavigation"
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
    ++ onlyArm [
      legcord
    ]
    ++ onlyX86 [
      discord
      slack
      spotify
    ];
}
