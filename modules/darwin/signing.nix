{
  config,
  ...
}:
{
  nix-darwin = {
    signing = {
      identity = "BB1BB693926CD713650B9E59640948A05662E5D3";
      teamId = "35D5DBPJAL";
      user = config.me.username;
    };
    signedPackages = {
      cua-driver = { };
    };
  };
}
