{
  config,
  lib,
  pkgs,
  ...
}:
let
  p10k = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
  vcsExpansion = arg: "\${$((my_git_formatter_ansi(${arg})))+\${my_git_format}}";
in
{
  imports = [
    ./niri
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

    home.file.".hushlogin" = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isDarwin { text = ""; };

    # p10k instant prompt, must stay at the top of ~/.zshrc
    programs.zsh.initContent = lib.mkMerge [
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      ''
        # powerlevel10k: upstream "lean" preset, trimmed to a single line
        source ${p10k}/config/p10k-lean.zsh
        typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
          context dir vcs background_jobs prompt_char
        )
        typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time)
        # like starship's truncate_to_repo: inside a git repo, start the path at the repo root
        typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER=.git
        typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=last
        typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
        typeset -g POWERLEVEL9K_STATUS_ERROR=true
        typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=2
        typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
        typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

        # no folder/forge icons, starship-style branch icon
        typeset -g POWERLEVEL9K_DIR_VISUAL_IDENTIFIER_EXPANSION=
        typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION=
        typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=' '

        # use the terminal's ANSI palette (gruvbox) instead of fixed 256-colour values
        typeset -g POWERLEVEL9K_DIR_FOREGROUND=6
        typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=14
        typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=8
        typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=2
        typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=1
        typeset -g POWERLEVEL9K_STATUS_{OK,OK_PIPE}_FOREGROUND=2
        typeset -g POWERLEVEL9K_STATUS_{ERROR,ERROR_SIGNAL,ERROR_PIPE}_FOREGROUND=1
        typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=3
        typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=2
        typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND=3
        typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=1
        typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED}_FOREGROUND=2
        typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=3
        # the lean preset's git formatter hardcodes its colours, remap them in its output
        function my_git_formatter_ansi() {
          my_git_formatter "$@"
          local from to
          for from to in 76 2 178 3 39 4 196 1; do
            my_git_format=''${my_git_format//\%''${from}F/%''${to}F}
          done
        }
        functions -M my_git_formatter_ansi 2>/dev/null
        typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${vcsExpansion "1"}'
        typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${vcsExpansion "0"}'
        source ${p10k}/powerlevel10k.zsh-theme

        source ${./ssh-tint.zsh}
      ''
    ];
  };
}
