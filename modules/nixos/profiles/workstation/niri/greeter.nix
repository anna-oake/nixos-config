{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.profiles.workstation.niri;
  user = config.me.username;
  niri = config.programs.niri.package;

  niriSettings = config.home-manager.users.${user}.programs.niri.settings;

  journal = tag: "${pkgs.systemd}/bin/systemd-cat -t ${tag}";

  # The greeter user's home is /var/empty, so without this Mesa and Quickshell
  # recompile every shader and QML file on each boot.
  cacheDir = "/var/cache/signalis-greeter";

  greeterConfig = pkgs.signalis-shell.mkGreeterConfig {
    inherit niri user;
    session = "${journal "niri-session"} ${niri}/bin/niri-session";
    # Only the default layout, and no toggle: passwords are always typed in it.
    xkb.layout = lib.head (lib.splitString "," niriSettings.input.keyboard.xkb.layout);
    inherit (niriSettings) outputs;
    inherit (config.stylix) cursor;
  };
in
{
  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session.command = "${pkgs.coreutils}/bin/env XDG_CACHE_HOME=${cacheDir} ${journal "signalis-greeter"} ${lib.getExe niri} --config ${greeterConfig}";
    };

    systemd.services.greetd = lib.mkIf config.boot.plymouth.enable {
      unitConfig = {
        After = lib.mkForce [
          "systemd-user-sessions.service"
          "getty@tty1.service"
          "plymouth-start.service"
        ];
        Conflicts = [ "plymouth-quit.service" ];
        OnFailure = [ "plymouth-quit.service" ];
      };
      serviceConfig = {
        ExecStartPre = "-${config.boot.plymouth.package}/bin/plymouth quit --retain-splash";
        Type = lib.mkForce "simple";
      };
    };

    systemd.tmpfiles.rules = [ "d ${cacheDir} 0700 greeter greeter -" ];
    disko.simple.impermanence.persist.directories = [
      {
        directory = cacheDir;
        user = "greeter";
        group = "greeter";
        mode = "0700";
      }
    ];

    users.users.greeter.extraGroups = [ "video" ];

    security.pam.services.login.fprintAuth = false;
  };
}
