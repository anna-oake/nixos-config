{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    apple-silicon-support.url = "github:nix-community/nixos-apple-silicon";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nix-things = {
      url = "github:oake/nix-things";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-unstable.follows = "nixpkgs";
      inputs.blueprint.follows = "blueprint";
    };

    jovian = {
      url = "github:jovian-experiments/jovian-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (inputs.nix-things.lib)
        mkDiskoChecks
        mkLxcChecks
        mkDeployChecks
        mkDeployNodes
        mkBootstrapScripts
        ;

      blueprint = inputs.blueprint {
        inherit inputs;
        nixpkgs.config.allowUnfree = true;
      };

      mkModules =
        modules:
        modules
        // {
          default = {
            imports = lib.attrsets.attrValues modules;
          };
        };
    in
    {
      inherit (blueprint)
        nixosConfigurations
        darwinConfigurations
        homeModules
        lib
        ;

      commonModules = mkModules blueprint.modules.common;
      lxcModules = mkModules blueprint.modules.lxc;
      nixosModules = mkModules blueprint.nixosModules;
      darwinModules = mkModules blueprint.darwinModules;

      checks = lib.foldl' lib.recursiveUpdate blueprint.checks [
        (mkDiskoChecks blueprint.nixosConfigurations)
        (mkLxcChecks blueprint.nixosConfigurations)
        mkDeployChecks
      ];

      packages = mkBootstrapScripts blueprint.nixosConfigurations;

      deploy.nodes =
        let
          inherit ((import inputs.self.commonModules.me).config.me) lanDomain;
        in
        mkDeployNodes lanDomain blueprint.nixosConfigurations;

      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = inputs.self;
        nixosConfigurations = blueprint.nixosConfigurations // blueprint.darwinConfigurations;
      };
    };
}
