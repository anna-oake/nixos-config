# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix` defines Nix flake inputs/outputs for darwin and nixos configurations.
- `hosts/` contains per-machine configs (e.g., `hosts/ara`, `hosts/lxc-lancache`).
- `modules/common`, `modules/nixos`, `modules/darwin` hold shared and platform-specific modules.
- `lib/` includes shared Nix helpers.
- `secrets/` stores agenix-encrypted secrets and master keys.
- `justfile` and `shared.just` provide common automation commands.

## Build, Test, and Development Commands
- `just --list` lists available tasks.
- `just bootstrap {target-host}` generates bootstrap artifacts for a host.
- `just install {target-host}` installs via nixos-anywhere or LXC depending on host name.
- `just deploy host1 host2 --remote|--local` deploys one or more hosts with deploy-rs (flags optional).
- `just rebuild` runs `darwin-rebuild switch` on the local macOS system.
- `nix flake check` runs flake checks (including deploy/bootstrap checks).

## Coding Style & Naming Conventions
- Nix code is formatted with `nixfmt` (see `treefmt.toml`); format with `nixfmt path/to/file.nix`.
- Keep module and host names lowercase with hyphens (e.g., `lxc-net-router`).
- Prefer small, composable modules under `modules/` and keep host files focused on wiring.

## Testing Guidelines
- There are no unit tests in this repository.
- Use `nix flake check` before changes that affect module wiring or deployment behavior.

## Commit & Pull Request Guidelines
- Commit messages follow a short scope prefix (e.g., `darwin: add fusion and codex`, `flake.lock: update`).
- Keep PRs focused: include a concise summary, affected hosts/modules, and any install/deploy steps run.
- If secrets change, note whether you ran `just rekey` or edited with `just secret {name}`.

## Security & Configuration Tips
- Secrets are managed with agenix; do not store plaintext secrets.
- Use `just secret {name}` to edit and `just rekey` to rotate keys.
