{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  skills = lib.genAttrs [
    "bom"
    "datasheets"
    "digikey"
    "element14"
    "emc"
    "jlcpcb"
    "kicad"
    "lcsc"
    "mouser"
    "pcbway"
    "spice"
  ] (name: "${pkgs.kicad-happy-skills}/share/kicad-happy-skills/${name}");
in
{
  config = lib.mkIf config.profiles.workstation.personal.enable (
    {
      home.packages = [ pkgs.python3 ];

      programs = {
        mcp = {
          enable = true;
          servers.mcpproxy.url = "http://127.0.0.1:3333/mcp";
        };
        codex = {
          inherit skills;
          enable = true;
          mutableSettings = true;
          enableMcpIntegration = true;
        };
        claude-code = {
          inherit skills;
          enable = true;
          mutableSettings = true;
          enableMcpIntegration = true;
        };
        opencode = {
          inherit skills;
          enable = true;
          enableMcpIntegration = true;
        };
        grok-build = {
          inherit skills;
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
