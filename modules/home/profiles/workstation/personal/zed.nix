{
  lib,
  config,
  pkgs,
  ...
}:
let
  ccTweakedLuaDefinitions = pkgs.fetchFromGitLab {
    owner = "carsakiller";
    repo = "lls-addon-cc-tweaked";
    rev = "2f489b0bd6df655ab00b465d6f9f5f48a30a1e81";
    hash = "sha256-5HzOSrwgBM6pKF/To3VQK2FK5BtDh4J5zvCiIIAqaO0=";
  };
in
{
  config = lib.mkIf config.profiles.workstation.personal.enable {
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
        "sieve"
      ];
      extraPackages = [
        pkgs.gopls
        pkgs.lua-language-server
      ];
      userTasks = [
        {
          label = "CraftOS-PC: Open project";
          command = "${pkgs.craftos-pc}/bin/craftos";
          args = [
            "--hardware"
            "--mount-ro"
            "project=$ZED_WORKTREE_ROOT"
          ];
          cwd = "$ZED_WORKTREE_ROOT";
          reveal = "always";
        }
        {
          label = "CraftOS-PC: Run $ZED_RELATIVE_FILE";
          command = "${pkgs.craftos-pc}/bin/craftos";
          args = [
            "--hardware"
            "--mount-ro"
            "project=$ZED_WORKTREE_ROOT"
            "--script"
            "$ZED_FILE"
          ];
          cwd = "$ZED_WORKTREE_ROOT";
          reveal = "always";
        }
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
          Lua = {
            formatter = "language_server";
            format_on_save = "on";
            semantic_tokens = "combined";
            inlay_hints = {
              enabled = true;
              show_type_hints = true;
              show_parameter_hints = true;
              show_other_hints = true;
            };
          };
        };
        lsp."lua-language-server".settings.Lua = {
          runtime = {
            version = "Lua 5.2";
            builtin = {
              bit32 = "enable";
              utf8 = "enable";
            };
          };
          workspace = {
            library = [ "${ccTweakedLuaDefinitions}/library" ];
            checkThirdParty = false;
          };
          format.enable = true;
          hint.enable = true;
        };
        telemetry = {
          metrics = false;
          diagnostics = false;
        };
        load_direnv = "shell_hook";
        agent_servers = lib.mkIf pkgs.stdenvNoCC.isLinux {
          "Codex" = {
            type = "custom";
            command = "${pkgs.codex-acp}/bin/codex-acp";
          };
        };
      };
    };
  };
}
