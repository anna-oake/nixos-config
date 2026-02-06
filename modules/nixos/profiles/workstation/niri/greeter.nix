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

  greeterConfig = pkgs.signalis-shell.mkGreeterConfig {
    inherit niri user;
    session = "${niri}/bin/niri-session";
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
      settings.default_session.command = "${lib.getExe niri} --config ${greeterConfig}";
    };

    users.users.greeter.extraGroups = [ "video" ];

    security.pam.services.login.fprintAuth = false;
  };
}
