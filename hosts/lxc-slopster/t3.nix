{
  lib,
  pkgs,
  ...
}:
{
  services.t3-server = {
    enable = true;
    user = "slopster";
    group = "slopster";
    lan = true;
    openFirewall = true;
    browserExecutable = lib.getExe pkgs.chromium;
  };
}
