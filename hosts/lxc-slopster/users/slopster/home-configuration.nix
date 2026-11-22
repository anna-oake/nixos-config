{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.homeModules.default
  ];

  programs = {
    ai = {
      enable = true;
      enableMcpProxyIntegration = true;
      agents = {
        codex = true;
        claude-code = true;
        grok-build = true;
        opencode = true;
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
