{
  config,
  pkgs,
  ...
}:
{
  users.mutableUsers = false;

  users.users.root.openssh.authorizedKeys.keys = [
    config.me.sshKey
  ];

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
  ];
}
