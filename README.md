# NixOS & Darwin Configuration

This repository contains my personal NixOS and macOS (darwin) configurations, powered by [Nix Flakes](https://nixos.wiki/wiki/Flakes) and [numtide/blueprint](https://github.com/numtide/blueprint).

It is designed for modularity, ease of deployment, and secure secret management.

##  Project Structure

- [`hosts/`](./hosts): Device-specific configurations (NixOS, Darwin, and LXC).
- [`modules/`](./modules): Reusable logic categorized into `common`, `nixos`, and `darwin`.
- [`secrets/`](./secrets): Encrypted secrets using `agenix-rekey`.
- [`lib/`](./lib): Custom Nix helper functions.
- [`justfile`](./justfile): Command runner for common tasks like bootstrapping and deployment.

##  Key Workflows

### 1. Fresh NixOS Installation
0.  **Prepare**: If using a YubiKey, ensure it's plugged in.
1.  **Bootstrap**: From your local machine, run:
    ```bash
    just bootstrap <target-host>
    ```
2.  **Wait**: Push changes and wait for the CI/cache to build.
3.  **Boot**: Boot the target machine into a NixOS live environment (via PXE or USB).
4.  **Install**: From your local machine, run:
    ```bash
    just install <target-host>
    ```

### 2. Creating a new LXC
1.  **Host Config**: Create a new host entry in `hosts/lxc-<name>`.
2.  **Import**: Import `flake.lxcModules.default` in the host's configuration.
3.  **Deploy**: Follow the bootstrap/install steps as described above.

### 3. Remote Updates
To update an existing host remotely:
```bash
just deploy <target-host>
```

##  Tech Stack
- **Framework**: [numtide/blueprint](https://github.com/numtide/blueprint)
- **Deployment**: [deploy-rs](https://github.com/serokell/deploy-rs) (via `nix-things`)
- **Disk Partitioning**: [disko](https://github.com/nix-community/disko)
- **Secret Management**: [agenix-rekey](https://github.com/oddlama/agenix-rekey)
- **Darwin Management**: [nix-darwin](https://github.com/LnL7/nix-darwin)

---
*Inspired by [maeve-oake/nixos-config](https://github.com/maeve-oake/nixos-config).*
