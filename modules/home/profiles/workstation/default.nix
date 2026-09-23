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

    # Personal workstations use atuin for history search instead.
    programs.fzf.enable = !config.profiles.workstation.personal.enable;
    programs.zoxide = {
      enable = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
