{
  lib,
  ...
}:
{
  options.lxc.profiles.share = {
    enable = lib.mkEnableOption "share profile";
    secretsDomain = lib.mkOption {
      type = lib.types.str;
      default = "lxc-share";
      description = "The subpath for the agenix secrets.";
    };
  };

  imports = [
    ./samba.nix
    ./sftp.nix
    ./users.nix
  ];
}
