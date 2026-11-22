{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.personal.enable {
    programs.ai = {
      enable = true;
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
    };
  };
}
