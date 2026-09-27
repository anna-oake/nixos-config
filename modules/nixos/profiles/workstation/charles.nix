{
  config,
  lib,
  pkgs,
  ...
}:
let
  cert = ./charles-ca.pem;
  bundle = "/etc/ssl/certs/ca-certificates.crt";
in
{
  config = lib.mkIf config.profiles.workstation.enable {
    security.pki.certificateFiles = [ cert ];

    # nixpkgs' certifi (requests, aiohttp in decky-loader, ...) falls back to the
    # stock cacert bundle unless NIX_SSL_CERT_FILE points at the system one.
    environment.sessionVariables.NIX_SSL_CERT_FILE = bundle;
    systemd.globalEnvironment.NIX_SSL_CERT_FILE = bundle;

    programs.chromium.extraOpts.CACertificates = [
      (lib.concatStrings (
        lib.filter (line: !lib.hasPrefix "-----" line) (lib.splitString "\n" (builtins.readFile cert))
      ))
    ];

    # CEF (Steam's browser, Electron apps) only trusts the per-user NSS database.
    systemd.user.services.charles-ca-nssdb = {
      description = "Trust the Charles CA in the user NSS database";
      wantedBy = [ "default.target" ];
      path = [ pkgs.nssTools ];
      serviceConfig.Type = "oneshot";
      script = ''
        db="$HOME/.pki/nssdb"
        if [ ! -e "$db/cert9.db" ]; then
          mkdir -p "$db"
          certutil -d "sql:$db" -N --empty-password
        fi
        certutil -d "sql:$db" -A -n "Charles Proxy CA" -t "C,," -i ${cert}
      '';
    };
  };
}
