{
  config,
  pkgs,
  inputs,
  ...
}:
{
  age.secrets."lxc-builder/attic-auth-token".rekeyFile =
    "${inputs.self}/secrets/secrets/lxc-builder/attic-auth-token.age";
  systemd.services.attic-watch-store = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment.HOME = "/var/lib/attic-watch-store";
    serviceConfig = {
      DynamicUser = true;
      MemoryHigh = "5%";
      MemoryMax = "10%";
      LoadCredential = "attic-auth-token:${config.age.secrets."lxc-builder/attic-auth-token".path}";
      StateDirectory = "attic-watch-store";
    };
    path = [ pkgs.attic-client ];
    script = ''
      set -eux -o pipefail
      ATTIC_TOKEN=$(< $CREDENTIALS_DIRECTORY/attic-auth-token)
      attic login attic https://attic.oa.ke $ATTIC_TOKEN
      attic use nixos
      exec attic watch-store attic:nixos
    '';
  };
}
