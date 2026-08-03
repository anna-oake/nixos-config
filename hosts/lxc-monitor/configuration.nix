{
  inputs,
  config,
  pkgs,
  ...
}:
let
  opensearch_2_19 = pkgs.opensearch.overrideAttrs (
    finalAttrs: previousAttrs: {
      version = "2.19.2";
      src = pkgs.fetchurl {
        url = "https://artifacts.opensearch.org/releases/bundle/opensearch/${finalAttrs.version}/opensearch-${finalAttrs.version}-linux-x64.tar.gz";
        hash = "sha256-EaOx8vs3y00ln7rUiaCGoD+HhiQY4bhQAzu18VfaTYw=";
      };

      # The agent directory was added in OpenSearch 3.x.
      installPhase =
        builtins.replaceStrings [ " plugins agent $out" ] [ " plugins $out" ]
          previousAttrs.installPhase;
    }
  );
in
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.monitor.enable = true;

  profiles.server.net-router = {
    enable = true;
    port = 30305;
    enableForwarding = false;
    tokenType = "monitor";
  };

  # funny right?
  monitoring.logs.systemd.enable = false;

  services.opensearch.package = opensearch_2_19;

  lxc = {
    enable = true;
    memory = 8192;
    mounts = [
      "lxc:monitor-storage,mp=/storage,backup=1,size=100G"
    ];
    network = "vmbr1"; # important! this is deployed to a router where vmbr0 is WAN
    pve.host = "kolibri." + config.me.lanDomain;
  };

  system.stateVersion = "25.11";
}
