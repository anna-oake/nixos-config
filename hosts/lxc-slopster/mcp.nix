{
  config,
  pkgs,
  ...
}:
{
  users.groups.protonmail-bridge = { };
  users.users.protonmail-bridge = {
    isSystemUser = true;
    group = "protonmail-bridge";
    home = "/var/lib/protonmail-bridge";
    createHome = true;
    homeMode = "700";
  };

  systemd.services.protonmail-bridge = {
    wantedBy = [ "multi-user.target" ];
    before = [ "mcpproxy.service" ];
    environment.HOME = "/var/lib/protonmail-bridge";
    serviceConfig = {
      User = "protonmail-bridge";
      Group = "protonmail-bridge";
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
      Restart = "always";
    };
  };

  age.secrets = {
    "lxc-slopster/mcpproxy/encryption-key" = { };
    "lxc-slopster/mcpproxy/oidc-client-secret" = { };
  };

  services.mcpproxy = {
    enable = true;

    user = "slopster";
    group = "slopster";

    path = with pkgs; [
      bash
      nodejs-slim
      nodejs-slim.npm
    ];

    settings = {
      listen = "0.0.0.0:3333";

      encryptionKeyFile = config.age.secrets."lxc-slopster/mcpproxy/encryption-key".path;

      oidc = {
        issuer = "https://auth.oa.ke";
        clientId = "0aa2cdde-c7c4-42a8-869a-a8e7ffecbc61";
        clientSecretFile = config.age.secrets."lxc-slopster/mcpproxy/oidc-client-secret".path;
      };
    };
  };
}
