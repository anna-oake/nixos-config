{
  config,
  ...
}:
{
  users.users = {
    anna = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        config.me.sshKey
      ];
    };
    maeve = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        config.me.wifeKey
      ];
    };
    buildbot = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsNNUQcW3ZoU82ugdgDjGh7UxnlDwzPVNCg2B2aOuQF"
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  nix.settings.trusted-users = [
    "@wheel"
    "buildbot"
  ];
}
