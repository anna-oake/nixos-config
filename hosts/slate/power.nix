{
  ...
}:
{
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  powerManagement.powertop.enable = true;
  # auto-tune runs after udev and sets this back to auto. Write the node directly.
  # udevadm trigger here deadlocks a switch that is also restarting systemd-udevd.
  powerManagement.powertop.postStart = ''
    for control in /sys/bus/pci/drivers/mei_me/0000:*/power/control \
      /sys/bus/hid/drivers/hid-multitouch/*/power/control
    do
      [ -e "$control" ] || continue
      printf on > "$control"
    done
  '';

  # niri handles the power key (power menu), keep logind from powering off
  services.logind.settings.Login.HandlePowerKey = "ignore";

  services.udev.extraRules = ''
    # allow the keyboard (via the surface aggregator) to wake from s2idle
    ACTION=="add|bind", SUBSYSTEM=="serial", ENV{MODALIAS}=="acpi:MSHW0084:", ATTR{power/wakeup}="enabled"

    # IPTS hangs off this device; runtime suspend leaves the touchscreen dead
    ACTION=="bind", SUBSYSTEM=="pci", DRIVER=="mei_me", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="bind", SUBSYSTEM=="hid", DRIVER=="hid-multitouch", TEST=="power/control", ATTR{power/control}="on"
  '';
}
