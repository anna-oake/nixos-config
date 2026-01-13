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
      {
        identity = inputs.self.outPath + "/secrets/master-keys/agenix-master-pq.key";
        pubkey = builtins.readFile (inputs.self.outPath + "/secrets/master-keys/agenix-master-pq.pub");
      }
    ];
  };
}
