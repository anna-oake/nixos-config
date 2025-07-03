{
  pkgs,
  lib,
  ...
}:
{
  options = {
    boot.splash.enable = lib.mkEnableOption "splash screen boot" // {
      default = lib.mkDefault true;
    };
  };
  config = {
    boot = {
      plymouth = {
        enable = true;
        themePackages = [ pkgs.plymouth-blahaj-theme ];
        theme = "blahaj";
      };
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
        "fbcon=nodefer"
        "vt.global_cursor_default=0"
      ];
      loader.grub.splashImage = null;
    };
  };
}
