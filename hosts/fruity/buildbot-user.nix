{
  pkgs,
  ...
}:
{
  users.knownUsers = [ "buildbot" ];

  users.users.buildbot = {
    isHidden = true;
    shell = pkgs.zsh;
    description = "Buildbot remote builder";
    uid = 3000;
    createHome = false;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsNNUQcW3ZoU82ugdgDjGh7UxnlDwzPVNCg2B2aOuQF"
    ];
  };

  system.activationScripts.postActivation.text = ''
    echo "allowing buildbot access over ssh"
    /usr/sbin/dseditgroup -o edit -a buildbot -t user com.apple.access_ssh 2>/dev/null || true
  '';

  nix.settings.trusted-users = [ "buildbot" ];
}
