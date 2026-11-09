{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    inputs.hermes-agent.nixosModules.default
  ];

  profiles.server.enable = true;

  age.secrets = {
    "lxc-slopster/telegram-token" = { };
  };

  services.hermes-agent = {
    enable = true;
    # TODO: drop once hermes-agent stops patching patchelf for 0.19.2 (nixpkgs reverted to 0.15.2)
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      pmPackages = lib.filterAttrs (_: lib.isDerivation) (
        pkgs.callPackage "${inputs.hermes-agent}/nix/pm-packages.nix" {
          # turns their `patchelf.overrideAttrs (… patch …)` into plain patchelf
          patchelf = pkgs.patchelf // {
            overrideAttrs = _: pkgs.patchelf;
          };
        }
      );
    };
    stateDir = "/storage-fast/slopster";
    addToSystemPackages = true;

    extraPackages = with pkgs; [
      nix
      ripgrep
      gh
      go
      python3
      temurin-bin-25
    ];

    extraDependencyGroups = [
      "messaging"
    ];

    environmentFiles = [
      config.age.secrets."lxc-slopster/telegram-token".path
    ];

    settings = {
      model = {
        provider = "openai-codex";
        default = "gpt-5.6-sol";
      };
      fallback_providers = [
        {
          provider = "xai-oauth";
          model = "grok-4.6";
        }
      ];
      mcp_servers = {
        pcbparts = {
          url = "https://pcbparts.dev/mcp";
        };
      };
      toolsets = [
        "all"
      ];
      approvals.mode = "off";
      compression.enabled = true;
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      display = {
        tool_progress = "off";
        tool_progress_command = false;
        streaming = true;
      };
      streaming.enabled = true;
      cron.wrap_response = false;
    };
  };

  lxc = {
    enable = true;
    memory = 4096;
    mounts = [
      "/storage-fast/slopster,mp=/storage-fast/slopster"
    ];
  };

  system.stateVersion = "25.11";
}
