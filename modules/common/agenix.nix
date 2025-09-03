{
  inputs,
  hostName,
  lib,
  config,
  ...
}:
let
  ageMasterIdentities = [
    (inputs.self.outPath + "/secrets/master-keys/yubikey-a.pub")
  ];
  publicKeyRelPath = "secrets/public-keys/${hostName}.pub";
  publicKeyAbsPath = inputs.self.outPath + "/" + publicKeyRelPath;
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  options = {
    age.ready = lib.mkOption {
      type = lib.types.bool;
      default = builtins.pathExists publicKeyAbsPath;
    };
  };

  config = {
    warnings = [
      (lib.mkIf (!config.age.ready) ''
        After initial target provisioning, fetch the target ssh identity:

          ssh-keyscan -qt ssh-ed25519 $target | cut -d' ' -f2,3 > ./${publicKeyRelPath}

        And rebuild NixOS.
      '')
    ];

    age.rekey = {
      masterIdentities = ageMasterIdentities;
      localStorageDir = inputs.self.outPath + "/secrets/rekeyed/${hostName}";
      secretsDir = inputs.self.outPath + "/secrets/secrets";
      storageMode = "local";
    }
    // lib.optionalAttrs config.age.ready {
      hostPubkey = builtins.readFile publicKeyAbsPath;
    };
  };
}
