{
  ...
}:
{
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  powerManagement.powertop.enable = true;

  # niri handles the power key (power menu), keep logind from powering off
  services.logind.settings.Login.HandlePowerKey = "ignore";

  # allow the keyboard (via the surface aggregator) to wake from s2idle
  services.udev.extraRules = ''
    ACTION=="add|bind", SUBSYSTEM=="serial", ENV{MODALIAS}=="acpi:MSHW0084:", ATTR{power/wakeup}="enabled"
  '';
}
