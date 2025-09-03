{
  lib,
  config,
  ...
}:
{
  config.assertions = [
    {
      assertion = (lib.count (p: p.enable) (builtins.attrValues config.lxc.profiles)) <= 1;
      message = "Only one lxc.profiles.<name>.enable can be set to true.";
    }
  ];
  imports = [
    ./share
    ./net-router
  ];
}
