{
  pkgs,
  flake,
  onlyArm,
  onlyX86,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    flake.nixosModules.default
  ];

  hardware.asahi.peripheralFirmwareDirectory = ./firmware;

  boot.extraModprobeConfig = ''
    options hid_apple iso_layout=1
  '';

  boot.loader.grub.configurationLimit = 3;

  services.automatic-timezoned.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # fix electron blur
  };

  programs.direnv.enable = true;
  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs.chromium = {
    enable = true;
    extraOpts = {
      "ExtensionManifestV2Availability" = 2;
    };
    extensions = [
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1password
      "ijcpiojgefnkmcadacmacogglhjdjphj" # shinigami eyes
    ];
  };

  environment.systemPackages =
    with pkgs;
    [
      gnomeExtensions.appindicator
      btrfs-progs
      boot-macos

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
            golang.go
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
    ]
    ++ onlyArm [
      legcord
    ]
    ++ onlyX86 [
      discord
      slack
      spotify
    ];

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  system.stateVersion = "25.11";
}
