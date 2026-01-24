{
  pkgs,
  ...
}:
{
  programs.arqbackup.enable = true;
  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs.direnv.enable = true;

  homebrew.masApps = {
    "Xcode" = 497799835;
    "TestFlight" = 899247664;
    "Numbers" = 409203825;
    "Windows App" = 1295203466;
    # Safari extensions:
    "1Password for Safari" = 1569813296;
    "Control Panel for Twitter" = 1668516167;
    "Userscripts" = 1463298887;
    "Kagi for Safari" = 1622835804;
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
    spotify
    ffmpeg-full
    imhex
    keka
    codex
    codex-acp
    proxmoxbar
    utm
  ];

  homebrew.casks = [
    "telegram"
    "ghostty"
    "github"
    "bambu-studio"
    "cleanshot"
    "httpie-desktop"
    "charles" # installs from nixpkgs but doesn't show up as .app
    "ocenaudio"
    "loopback"
    "transmit"
    "mist"
    "plex"
    "protonvpn"
    "dosbox"
    "autodesk-fusion"
    "helium-browser"
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    comic-code-font
  ];
}
