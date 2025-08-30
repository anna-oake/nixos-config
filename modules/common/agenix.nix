{
  inputs,
  hostName,
  pkgs,
  lib,
  config,
  ...
}:
let
  ageMasterIdentities = [
    (inputs.self.outPath + "/secrets/master-keys/yubikey-a.pub")
  ];
  publicKeyAbsPath = inputs.self.outPath + "/" + config.age.publicKeyRelPath;
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  options = {
    age.publicKeyRelPath = lib.mkOption {
      type = lib.types.str;
      default = "secrets/public-keys/${hostName}.pub";
    };
    age.ready = lib.mkOption {
      type = lib.types.bool;
      default = builtins.pathExists publicKeyAbsPath;
    };
  };

  config = {
    environment.systemPackages = [
      pkgs.agenix-rekey
    ];

    nixpkgs.overlays = [
      inputs.agenix-rekey.overlays.default
    ];

    warnings = [
      (lib.mkIf (!config.age.ready) ''
        After initial target provisioning, fetch the target ssh identity:

          ssh-keyscan -qt ssh-ed25519 $target | cut -d' ' -f2,3 > ./${config.age.publicKeyRelPath}

        And rebuild NixOS.
      '')
    ];

    age.rekey = {
      masterIdentities = ageMasterIdentities;
      localStorageDir = inputs.self.outPath + "/secrets/rekeyed/${hostName}";
      storageMode = "local";
    }
    // lib.optionalAttrs config.age.ready {
      hostPubkey = builtins.readFile publicKeyAbsPath;
    };
  };
}
