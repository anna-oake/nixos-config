{
  pkgs,
  inputs,
  ...
}:
{
  programs.arqbackup.enable = true;
  programs._1password.enable = true;
  programs._1password-gui.enable = true;

  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
    "Control Panel for Twitter" = 1668516167;
    "Xcode" = 497799835;
  };

  environment.systemPackages = with pkgs; [
    gh
    git
    htop
    btop
    nixfmt
    nixd
    just
    raycast
    chatgpt
    slack
    discord
    element-desktop
    daisydisk
    hexfiend
    httpie
    go
    devenv
    uv
  ];

  homebrew.casks = [
    "telegram"
    "ghostty"
    "github"
    "bambu-studio"
    "cleanshot"
    "httpie-desktop"
    "spotify" # temporarily broken in nixpkgs
    "charles" # installs from nixpkgs but doesn't show up as .app
    "ocenaudio"
    "loopback"
    "transmit"
    "keka" # ancient in nixpkgs
    "mist"
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    comic-code-font
  ];
}
