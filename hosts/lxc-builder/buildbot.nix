{
  inputs,
  pkgs,
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
    "lxc-builder/gh-app-key" = { };
    "lxc-builder/gh-webhook-secret" = { };
    "lxc-builder/basic-auth-pwd" = {
      owner = "buildbot";
    };
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

    authBackend = "httpbasicauth";
    httpBasicAuthPasswordFile = config.age.secrets."lxc-builder/basic-auth-pwd".path;
    admins = [
      "maeve-oake"
      "anna-oake"
    ];

    github = {
      enable = true;
      authType.app = {
        id = 1885778;
        secretKeyFile = config.age.secrets."lxc-builder/gh-app-key".path;
      };
      webhookSecretFile = config.age.secrets."lxc-builder/gh-webhook-secret".path;
      topic = "oake-builder";
    };

    evalWorkerCount = 4;
    evalMaxMemorySize = 4096; # MB per evalWorker

    branches = {
      all-branches = {
        matchGlob = "*";
        registerGCRoots = false;
      };
    };
  };

  services.buildbot-nix.worker = {
    enable = true;
    name = hostName;
    workerPasswordFile = pkgs.writeText "worker-password-file" "its-local-anyway";
  };
}
