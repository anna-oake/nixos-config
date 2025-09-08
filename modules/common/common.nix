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

  system.configurationRevision = inputs.self.rev or "dirty";
}
