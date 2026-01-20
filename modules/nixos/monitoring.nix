{
  config,
  ...
}:
{
  monitoring.logs.target =
    if config.monitoring.machineType == "local" then "10.10.0.6" else "100.94.10.42";
}
