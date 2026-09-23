{
  lib,
  config,
  osConfig,
  ...
}:
let
  cfg = config.programs.atuin;
  keyPath = osConfig.age.secrets."atuin/key".path;
  passwordPath = osConfig.age.secrets."atuin/password".path;
in
{
  config = lib.mkIf config.profiles.workstation.personal.enable {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        update_check = false;
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://atuin.lan.al";
        key_path = keyPath;
        ai = {
          enabled = true;
          endpoint = "https://atuin.lan.al";
          endpoint_protocol = "oss";
        };
      };
    };

    home.activation.atuinLogin = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -r ${keyPath} ] && [ -r ${passwordPath} ]; then
        run ${lib.getExe cfg.package} login \
          -u ${lib.escapeShellArg osConfig.me.username} \
          -p "$(cat ${passwordPath})" \
          -k "" </dev/null >/dev/null \
          || errorEcho "atuin login failed; sync stays off until the next switch"
      fi
    '';
  };
}
