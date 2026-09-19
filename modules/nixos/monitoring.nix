{
  config,
  lib,
  ...
}:
{
  age.secrets.metrics-token = { };

  monitoring = {
    logs.target = if config.monitoring.machineType == "local" then "10.10.0.6" else "100.94.10.42";

    metrics = {
      enable = lib.mkDefault true;
      targetUrl = "https://dash.oa.ke";
      sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC8JsBD9HfQ5BYWYZLhAo3SDp06R/tnAJqkKSFKH6g0S";
      tokenFile = config.age.secrets.metrics-token.path;
    };
  };
}
