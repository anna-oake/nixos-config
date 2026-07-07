{
  pkgs,
  ...
}:
{
  services.netbird.package = pkgs.netbird.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./darwin-peer-domain-no-search.patch
    ];
  });
}
