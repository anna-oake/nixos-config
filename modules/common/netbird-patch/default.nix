{
  pkgs,
  ...
}:
{
  services.netbird.package = pkgs.netbird.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./lazy-routing-fix.patch
    ];
  });
}
