{
  inputs,
  config,
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

  environment.systemPackages = config.services.hermes-agent.extraPackages;

  services.hermes-agent = {
    enable = true;
    stateDir = "/storage-fast/slopster";
    addToSystemPackages = true;

    extraPackages = with pkgs; [
      nix
      ripgrep
      gh
      go
      python3
    ];

    environmentFiles = [
      config.age.secrets."lxc-slopster/telegram-token".path
    ];

    settings = {
      model = {
        default = "gpt-5.4";
        provider = "openai-codex";
        base_url = "https://chatgpt.com/backend-api/codex";
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
        tool_progress_command = true;
        streaming = true;
      };
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
