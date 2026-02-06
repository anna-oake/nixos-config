{
  config,
  lib,
  pkgs,
  ...
}:
let
  shell = pkgs.signalis-shell;
  target = config.wayland.systemd.target;

  unit = description: {
    Description = description;
    PartOf = [ target ];
    After = [ target ];
  };
in
{
  config = lib.mkIf config.profiles.workstation.niri.enable {
    systemd.user.services.signalis-shell = {
      Unit = unit "Signalis desktop shell";
      Service = {
        ExecStart = lib.getExe' shell "signalis-shell";
        Restart = "on-failure";
        Slice = "session.slice";
      };
      Install.WantedBy = [ target ];
    };

    systemd.user.services.signalis-lock = {
      Unit = unit "Signalis lock screen" // {
        X-SwitchMethod = "keep-old";
      };
      Service = {
        ExecStart = lib.getExe' shell "signalis-lock";
        Restart = "always";
        Slice = "session.slice";
      };
      Install.WantedBy = [ target ];
    };
  };
}
