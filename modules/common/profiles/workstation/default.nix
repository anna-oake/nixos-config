{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./personal
  ];
  config = lib.mkIf config.profiles.workstation.enable {
    environment.systemPackages = with pkgs; [
      git
      htop
      btop
      just
      wget
      p7zip
    ];
  };
}
