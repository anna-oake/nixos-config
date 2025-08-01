{
  flake,
  inputs,
  hostName,
  ...
}:
{
  class = "nixos";

  value = inputs.nix-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs flake hostName; };
    modules = [
      ./configuration.nix
    ];
  };
}
