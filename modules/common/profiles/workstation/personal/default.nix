{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.profiles.workstation.personal.enable {
    programs.direnv.enable = true;

    programs._1password.enable = true;
    programs._1password-gui.enable = true;

    environment.systemPackages = with pkgs; [
      gh
      nixfmt
      go
      nixd
      ffmpeg-full
      codex
      codex-acp
      zone-wizard
      element-desktop
      imhex
      httpie
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.symbols-only
      comic-code-font
    ];

    security.sudo.extraConfig =
      let
        rebuildBin = if pkgs.stdenv.isDarwin then "darwin-rebuild" else "nixos-rebuild";
      in
      lib.mkAfter ''
        ${config.me.username} ALL=(root) NOPASSWD: /run/current-system/sw/bin/${rebuildBin} switch --flake .
      '';
  };
}
