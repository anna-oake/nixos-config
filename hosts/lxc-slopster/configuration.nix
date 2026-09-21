{
  inputs,
  config,
  pkgs,
  ...
}:
let
  # Temporary workaround until our nixpkgs includes NixOS/nixpkgs#564554.
  # Skip only the Node 26 test that fails in the Linux build sandbox.
  hermesPkgs = pkgs.extend (
    final: prev: {
      nodejs-slim_26 = prev.nodejs-slim_26.overrideAttrs (old: {
        checkFlags = map (
          flag:
          if final.lib.hasPrefix "CI_SKIP_TESTS=" flag then
            "${flag},test-fs-cp-async-file-modes,test-fs-copyfile,test-fs-cp-async-with-mode-flags,test-fs-cp-promises-mode-flags"
          else
            flag
        ) old.checkFlags;
      });
    }
  );
in
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
    # Hermes uses its own flake package, so a host overlay alone is insufficient.
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      callPackage = hermesPkgs.callPackage;
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
