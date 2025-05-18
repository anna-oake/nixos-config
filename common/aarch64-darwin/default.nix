{
  pkgs,
  hostname,
  inputs,
  ...
}:
{
  # common configuration for macOS machines

  # networking
  networking.computerName = hostname;

  system.configurationRevision = self.rev or self.dirtyRev or null;
}
