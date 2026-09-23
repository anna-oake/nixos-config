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
    programs.starship = {
      enable = true;
      settings = {
        add_newline = false;
        status.disabled = false;

        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_commit"
          "$git_state"
          "$git_metrics"
          "$git_status"
          "$cmd_duration"
          "$jobs"
          "$status"
          "$character"
        ];
      };
    };

    programs.zsh.initContent = ''
      ssh() {
        printf '\e]11;#2a1a1a\a'
        command ssh "$@"
        local rc=$?
        printf '\e]111\a'
        return $rc
      }
    '';
  };
}
