{
  pkgs,
  inputs,
  lib,
  onlyArm,
  onlyX86,
  flake,
  ...
}:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nix-things.nixosModules.default
    flake.commonModules.default
  ];

  users.user = lib.mkDefault true;

  # boot
  boot.loader.timeout = 0;
  boot.splash = {
    enable = lib.mkDefault true;
    themePackage = pkgs.plymouth-feet-theme;
    theme = "feet";
  };

  # pkgs
  services.fwupd.enable = true;
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
