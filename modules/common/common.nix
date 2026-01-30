{
  inputs,
  hostName,
  ...
}:
{
  imports = [
    inputs.nix-things.commonModules.default
  ];

  networking.hostName = hostName;

  services.openssh.enable = true;

  system.configurationRevision = inputs.self.rev or "dirty";
}
