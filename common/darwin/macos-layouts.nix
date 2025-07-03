{
  config,
  lib,
  ...
}:

let
  cfg = config.macos-layouts;
in
{
  options = {
    macos-layouts = {
      enable = lib.mkEnableOption "keyboard layouts management";

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "List of packages containing Keyboard Layouts to install.";
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.postActivation.text =
      let
        installLayout = package: ''
          echo "installing keyboard layout ${package.name}..."
          cp -r "${package}/Library/Keyboard Layouts/"* "/Library/Keyboard Layouts/"
        '';

      in
      ''
        echo "cleaning up keyboard layouts..."
        rm -rf "/Library/Keyboard Layouts/"*
        ${lib.concatStringsSep "\n" (map installLayout cfg.packages)}
      '';

    system.defaults.CustomUserPreferences."com.apple.inputsources".AppleEnabledThirdPartyInputSources =
      map
        (layout: {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = layout.id;
          "KeyboardLayout Name" = layout.name;
        })
        (builtins.concatLists (map (p: p.layouts) cfg.packages));
  };
}
