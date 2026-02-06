{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./gnome
    ./laptop
    ./niri
    ./personal
    ./wifi
    ./localisation.nix
    ./network.nix
    ./user.nix
  ];

  config = lib.mkIf config.profiles.workstation.enable {
    # boot
    boot.loader.timeout = 0;
    boot.splash = {
      enable = lib.mkDefault true;
      themePackage = pkgs.plymouth-feet-theme;
      theme = "feet";
    };

    environment.sessionVariables = lib.optionalAttrs (!config.hardware.nvidia.enabled) {
      NIXOS_OZONE_WL = "1"; # fix electron blur
    };

    # pkgs
    services.fwupd.enable = true;
    environment.systemPackages = with pkgs; [
      usbutils
      pciutils
      # The flake's wrapper passes --disable-background-networking, which also
      # stops the extension downloader, so policy-installed extensions never arrive.
      (inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace $out/bin/helium --replace-fail " --disable-background-networking" ""
        '';
      }))
    ];

    # Helium is Chromium-based and reads Chromium's managed policies, so
    # programs.chromium (policies only, no browser) manages its extensions.
    programs.chromium.enable = true;
  };
}
