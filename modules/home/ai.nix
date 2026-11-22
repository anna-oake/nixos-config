{
  ...
}:
{
  programs.ai = {
    enableMcpProxyIntegration = true;
    agents = {
      codex = true;
      claude-code = true;
      grok-build = true;
      opencode = true;
    };
  };
}
