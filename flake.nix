{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nix-darwin";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;

      mkHost =
        system: hostname:
        let
          isDarwin = builtins.match ".*darwin$" system != null;
          builder = if isDarwin then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
          config = builder {
            inherit system;
            specialArgs = { inherit inputs; };
            modules = [
              ./common
              ./common/${system}
              ./hosts/${system}/${hostname}
              { config._module.args = { inherit system hostname; }; }
            ];
          };
          key = if isDarwin then "darwinConfigurations" else "nixosConfigurations";
        in
        {
          ${key} = {
            ${hostname} = config;
          };
        };

      systems = builtins.attrNames (builtins.readDir ./hosts);

      hosts = builtins.concatMap (
        system:
        let
          hostnames = builtins.attrNames (builtins.readDir (./hosts + "/${system}"));
        in
        map (hostname: mkHost system hostname) hostnames
      ) systems;

    in
    builtins.foldl' lib.recursiveUpdate { } hosts;
}
