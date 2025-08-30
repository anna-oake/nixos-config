@_default:
  just --list  --unsorted

# generate a keypair, rekey
@bootstrap host="":
  HOST={{host}} scripts/bootstrap.sh

# install with nixos-anywhere
@install host build="local":
  test -d .bootstrap/extra && [ "$(ls -A .bootstrap/extra)" ] \
    || { echo "Can't find the keypair. Did you bootstrap?"; exit 1; }

  nix run nixos-anywhere -- \
        --extra-files '.bootstrap/extra' \
        --build-on local \
        --flake '.#{{host}}' \
        root@{{host}}.lan.al

# use deploy-rs to update an existing host
@deploy host:
  nix run nixpkgs#deploy-rs -- .#{{host}} --remote-build