{
  pkgs,
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

  environment.systemPackages = with pkgs; [
    xrizer
  ];
}
