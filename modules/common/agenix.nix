{
  inputs,
  ...
}:
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  config = {
    age.rekey.masterIdentities = [
      (inputs.self.outPath + "/secrets/master-keys/yubikey-a.pub")
      {
        identity = "/Users/koteeq/.ssh/agenix-master";
        pubkey = builtins.readFile (inputs.self.outPath + "/secrets/master-keys/agenix-master.pub");
      }
    ];
  };
}
