{ config, ... }:
{
  age.secrets."infra-token" = { };
  infra = {
    flakeRepo = "anna-oake/nixos-config";
    hubTokenFile = config.age.secrets."infra-token".path;
  };
}
