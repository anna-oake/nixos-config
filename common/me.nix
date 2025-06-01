{ lib, inputs, ... }:
let
  userSubmodule = lib.types.submodule {
    options = {
      username = lib.mkOption {
        type = lib.types.str;
      };
      email = lib.mkOption {
        type = lib.types.str;
      };
      githubUsername = lib.mkOption {
        type = lib.types.str;
      };
      sshKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = ''
          SSH public keys
        '';
      };
    };
  };
in
{
  imports = [
    (inputs.self + /me.nix)
  ];
  options = {
    me = lib.mkOption {
      type = userSubmodule;
    };
  };
}
