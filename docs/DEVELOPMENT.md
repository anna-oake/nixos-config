# Developer Documentation

This document provides a deeper dive into the technical details and maintenance procedures for this configuration.

##  Architecture: Nix Blueprint

This project uses [numtide/blueprint](https://github.com/numtide/blueprint) to automatically discover and wire up NixOS, Darwin, and Home Manager configurations based on the directory structure.

- **`hosts/`**: Each subdirectory here represents a machine. Blueprint automatically creates `nixosConfigurations` or `darwinConfigurations` based on the content.
- **`modules/`**: Blueprint discovers modules here. We use `mkModules` in `flake.nix` to expose them as `default` imports for convenience.
- **`lib/`**: Custom Nix functions exported via `blueprint.lib`.

##  Secret Management with `agenix-rekey`

Secrets are managed using `agenix-rekey`, which allows editing secrets with a master key and then re-encrypting them for specific host keys.

### Initial Setup
Ensure your master identity is set in `justfile`:
```bash
export AGENIX_REKEY_PRIMARY_IDENTITY := `cat ./secrets/master-keys/agenix-master.pub`
```

### Adding/Editing Secrets
1.  Add a new secret file in `secrets/secrets/<name>.age`.
2.  Define it in a host's `age.rekey.storage` or use the `agenix-rekey` options.
3.  Run the rekeying command (usually provided by `nix-things` or `agenix-rekey` cli).

##  Adding a New Host

1.  Create a directory in `hosts/<new-host>`.
2.  Create a `default.nix` (or `nixos.nix`/`darwin.nix`) inside that directory.
3.  Include a `disko` configuration if it's a NixOS machine requiring partitioning.
4.  Add a `public-key` for the host in `secrets/public-keys/<new-host>.pub` for `agenix-rekey`.

##  Maintenance

### Updating Inputs
To update all flake inputs:
```bash
nix flake update
```

### Formatting
The project uses `treefmt` to maintain consistent styling.
```bash
nix fmt
```

### Updating `shared.just`
We pull shared recipes from `oake/nix-things`. Update them via:
```bash
just update-shared
```
