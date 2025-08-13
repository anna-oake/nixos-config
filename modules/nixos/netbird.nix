{
  lib,
  config,
  inputs,
  ...
}:
{
  age.secrets = lib.mkIf config.age.ready {
    netbird-personal.rekeyFile = (inputs.self + /secrets/netbird-personal.age);
  };

  services.netbird.clients = lib.optionalAttrs config.age.ready {
    oake.environment = {
      NB_MANAGEMENT_URL = "https://net.oa.ke";
      NB_SETUP_KEY_FILE = config.age.secrets.netbird-personal.path;
    };
  };
}
