@_default:
  just --list  --unsorted

# generate a keypair, rekey all secrets
[group('deployment')]
@bootstrap host="":
  HOST={{host}} scripts/bootstrap.sh

# install with nixos-anywhere
[group('deployment')]
@install host build="local":
  test -d .bootstrap/extra && [ "$(ls -A .bootstrap/extra)" ] \
    || { echo "Can't find the keypair. Did you bootstrap?"; exit 1; }

  nix run nixos-anywhere -- \
        --extra-files '.bootstrap/extra' \
        --build-on local \
        --flake '.#{{host}}' \
        root@{{host}}.lan.al

# use deploy-rs to update an existing host
[group('deployment')]
@deploy host:
  nix run nixpkgs#deploy-rs -- .#{{host}} --remote-build

# rekey all secrets
[group('secrets')]
@rekey:
  nix run github:oddlama/agenix-rekey -- rekey -a

# create/edit agenix secret
[group('secrets')]
@secret secret:
  EDITOR=nano nix run github:oddlama/agenix-rekey -- edit ./secrets/secrets/{{secret}}.age

# navigate config tree
[group('tools')]
@inspect:
  nix run nixpkgs#nix-inspect -- -p .