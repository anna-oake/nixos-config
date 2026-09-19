{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.profiles.server.enable {
    monitoring.metrics.enable = true;
  };
}
