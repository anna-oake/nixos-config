{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.personal.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          identityAgent =
            if pkgs.stdenv.isLinux then
              "~/.1password/agent.sock"
            else
              "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
        };
      };
    };

    programs.git = {
      enable = true;
      lfs.enable = true;
      settings.user = {
        email = osConfig.me.email;
        name = "Anna Oake";
      };
      signing = {
        key = osConfig.me.sshKey;
        format = "ssh";
        signByDefault = true;
      };
    };

    programs.zed-editor = {
      enable = true;
      extensions = [
        "nix"
        "just"
        "just-ls"
        "graphql"
        "toml"
        "git-firefly"
        "swift"
        "liquid"
        "lua"
      ];
      extraPackages = [
        pkgs.gopls
      ];
      userSettings = {
        ui_font_size = 15;
        buffer_font_size = 13;
        buffer_font_family = "Comic Code Ligatures";
        theme = {
          mode = "system";
          light = "Gruvbox Light";
          dark = "Gruvbox Dark";
        };
        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
          };
        };
        telemetry = {
          metrics = false;
          diagnostics = false;
        };
        load_direnv = "shell_hook";
      };
    };

    programs.ghostty = {
      enable = true;
      package = null;
      settings = {
        auto-update = "off";
        shell-integration = "zsh";
        shell-integration-features = "cursor,sudo,title";
        clipboard-read = "allow";
        clipboard-write = "allow";
        window-subtitle = "working-directory";
        window-colorspace = "display-p3";
        window-theme = "system";
        background-opacity = 0.95;
        background-blur = 20;
        unfocused-split-opacity = 0.3;
        macos-icon = "retro";
        keybind = "global:cmd+grave_accent=toggle_quick_terminal";
        theme = "Gruvbox Dark";

        font-size = 12;
        font-family = "Comic Code";
        font-feature = "-calt, -liga, -dlig";
        font-codepoint-map =
          let
            codepoints-map = {
              "Symbols Nerd Font Mono" = lib.concatStringsSep "," [
                "U+E000-U+E00D" # Pomicons
                "U+E0A0-U+E0A2,U+E0B0-U+E0B3" # Powerline
                "U+E0A3-U+E0A3,U+E0B4-U+E0C8,U+E0CC-U+E0D2,U+E0D4-U+E0D4" # Powerline Extra
                "U+E5FA-U+E62B" # Symbols original
                "U+E700-U+E7C5" # Devicons
                "U+F000-U+F2E0" # Font awesome
                "U+E200-U+E2A9" # Font awesome extension
                "U+F400-U+F4A8,U+2665-U+2665,U+26A1-U+26A1,U+F27C-U+F27C" # Octicons
                "U+F300-U+F313" # Font Linux
                "U+23FB-U+23FE,U+2B58-U+2B58" # Font Power Symbols
                "U+F500-U+FD46" # Material Design Icons
                "U+E300-U+E3EB" # Weather Icons
                "U+21B5,U+25B8,U+2605,U+2630,U+2632,U+2714,U+E0A3,U+E615,U+E62B" # Misc
              ];
            };
            generate =
              family: codepoints:
              lib.concatStringsSep "=" [
                codepoints
                family
              ];
          in
          lib.mapAttrsToList generate codepoints-map;
      };

      enableZshIntegration = true;
    };
  };
}
