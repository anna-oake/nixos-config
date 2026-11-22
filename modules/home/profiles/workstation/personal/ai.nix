{
  config,
  lib,
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
  config = lib.mkIf config.profiles.workstation.personal.enable {
    programs.ai = {
      enable = true;
      enableMcpProxyIntegration = true;
      agents = {
        codex = true;
        claude-code = true;
        grok-build = true;
        opencode = true;
      };
      inherit skills;
    };
  };
}
