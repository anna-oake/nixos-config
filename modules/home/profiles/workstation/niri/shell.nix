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
        # `:`, `?`, and desktop entries launched by the launcher run in this
        # service. The wrapper prepends its own tools to this path.
        Environment = [ "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin" ];
      };
      Install.WantedBy = [ target ];
    };

    systemd.user.services.signalis-lock = {
      # Restarted on switch like the shell; a restart while locked re-locks,
      # see lock.qml.
      Unit = unit "Signalis lock screen";
      Service = {
        ExecStart = lib.getExe' shell "signalis-lock";
        Restart = "always";
        Slice = "session.slice";
      };
      Install.WantedBy = [ target ];
    };
  };
}
