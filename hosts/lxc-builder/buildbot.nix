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
    "lxc-builder/basic-auth-pwd" = {
      rekeyFile = "${inputs.self}/secrets/secrets/lxc-builder/basic-auth-pwd.age";
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

    evalWorkerCount = 6;
    evalMaxMemorySize = 4096; # MB per evalWorker

    branches = {
      all-branches = {
        matchGlob = "*";
      };
    };
  };

  services.buildbot-nix.worker = {
    enable = true;
    name = hostName;
    workerPasswordFile = pkgs.writeText "worker-password-file" "its-local-anyway";
  };
}
