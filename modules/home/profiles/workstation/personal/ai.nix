{
  config,
  lib,
  options,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.personal.enable (
    {
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
      };
    }
    // lib.optionalAttrs (options ? stylix.targets.opencode.enable) {
      stylix.targets.opencode.enable = false;
    }
  );
}
