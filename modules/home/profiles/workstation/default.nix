{
  config,
  lib,
  ...
}:
{
  imports = [
    ./personal
  ];

  config = lib.mkIf config.profiles.workstation.enable {
    programs.zsh.enable = true;
    programs.zsh.dotDir = config.home.homeDirectory;
    programs.zsh.oh-my-zsh.enable = true;

    programs.fzf.enable = true;
    programs.zoxide = {
      enable = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
