{
  ...
}:
{
  services.wivrn = {
    enable = true;
    openFirewall = true;
    defaultRuntime = true;
    autoStart = true;
    steam.importOXRRuntimes = true;
    highPriority = true;
  };
}
