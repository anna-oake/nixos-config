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
        identity = "/Users/anna/.ssh/agenix-master-pq";
        pubkey = builtins.readFile (inputs.self.outPath + "/secrets/master-keys/agenix-master-pq.pub");
      }
    ];
  };
}
