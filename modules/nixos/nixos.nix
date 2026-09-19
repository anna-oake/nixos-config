{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.nix-things.nixosModules.default
    inputs.self.commonModules.default
  ];

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Bound boot partition usage when deploying repeatedly without rebooting.
  boot.loader = {
    grub.configurationLimit = 2;
    systemd-boot.configurationLimit = 2;
    generic-extlinux-compatible.configurationLimit = 2;
  };

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
  ];

  monitoring.metrics.namePrefixes = lib.mkIf config.lxc.enable (
    lib.mkAfter [
      (builtins.head (lib.splitString "." config.lxc.pve.host))
    ]
  );
}
