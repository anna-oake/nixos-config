{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.homeModules.default
  ];

  programs = {
    mcp = {
      enable = true;
      servers.mcpproxy.url = "http://127.0.0.1:3333/mcp";
    };
    codex = {
      enable = true;
      mutableSettings = true;
      enableMcpIntegration = true;
    };
    claude-code = {
      enable = true;
      mutableSettings = true;
      enableMcpIntegration = true;
    };
    opencode = {
      enable = true;
      enableMcpIntegration = true;
    };
    grok-build = {
      enable = true;
      mutableSettings = true;
      enableMcpIntegration = true;
      settings.compat = {
        claude.mcps = false;
        cursor.mcps = false;
      };
    };
    uv = {
      enable = true;
      settings = {
        python-downloads = "never";
        python-preference = "only-system";
      };
    };
  };

  home.stateVersion = "25.11";
}
