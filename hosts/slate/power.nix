{
  ...
}:
{
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  powerManagement.powertop.enable = true;
  powerManagement.powertop.postStart = ''
    for control in /sys/bus/pci/drivers/mei_me/0000:*/power/control \
      /sys/bus/hid/drivers/hid-multitouch/*/power/control
    do
      [ -e "$control" ] || continue
      printf on > "$control"
    done
  '';

  boot.initrd.systemd.services.impermanence-wipe.after = [ "systemd-hibernate-resume.service" ];

  # niri handles the power key (power menu), keep logind from powering off
  services.logind.settings.Login.HandlePowerKey = "ignore";

  services.udev.extraRules = ''
    # IPTS hangs off this device; runtime suspend leaves the touchscreen dead
    ACTION=="bind", SUBSYSTEM=="pci", DRIVER=="mei_me", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="bind", SUBSYSTEM=="hid", DRIVER=="hid-multitouch", TEST=="power/control", ATTR{power/control}="on"
  '';
}
