{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.self.commonModules.default
    inputs.nix-things.lxcModules.default
  ];

  lxc.pve.host = lib.mkDefault ("mynah." + config.me.lanDomain);
}
