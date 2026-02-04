{
  config,
  lib,
  ...
}:
{
  imports = [
    ./niri
    ./personal
  ];

  config = lib.mkIf config.profiles.workstation.enable {
    programs.zsh.enable = true;
    programs.zsh.dotDir = config.home.homeDirectory;

    programs.fzf.enable = true;
    programs.zoxide = {
      enable = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
