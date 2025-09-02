{
  pkgs,
  inputs,
  hostName,
  config,
  ...
}:
{
  imports = [
    inputs.buildbot-nix.nixosModules.buildbot-master
    inputs.buildbot-nix.nixosModules.buildbot-worker
  ];

  age.secrets = {
    "lxc-builder/gh-app-key".rekeyFile = "${inputs.self}/secrets/secrets/lxc-builder/gh-app-key.age";
    "lxc-builder/gh-webhook-secret".rekeyFile =
      "${inputs.self}/secrets/secrets/lxc-builder/gh-webhook-secret.age";
  };

  services.buildbot-nix.master = {
    enable = true;

    domain = "builder.oa.ke";
    useHTTPS = true;

    workersFile = pkgs.writeText "workers.json" ''
      [
        { "name": "${hostName}", "pass": "its-local-anyway", "cores": 10 }
      ]
    '';

    authBackend = "none"; # protected by traefik

    github = {
      authType.app = {
        id = 1885567;
        secretKeyFile = config.age.secrets."lxc-builder/gh-app-key".path;
      };
      webhookSecretFile = config.age.secrets."lxc-builder/gh-webhook-secret".path;
      topic = "oake-builder";
    };

    evalWorkerCount = 6;
    evalMaxMemorySize = 4096; # MB per evalWorker

    branches = {
      all-branches = {
        matchGlob = "*";
        registerGCRoots = true;
        updateOutputs = true;
      };
    };
  };

  services.buildbot-nix.worker = {
    enable = true;
    name = hostName;
    workerPasswordFile = pkgs.writeText "worker-password-file" "its-local-anyway";
  };
}
