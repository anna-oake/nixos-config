@_default:
  just --list  --unsorted

# generate a keypair, rekey all secrets
[group('deployment')]
@bootstrap host: _add
  HOST={{host}} scripts/bootstrap.sh

# install with nixos-anywhere or LXC in PVE
[group('deployment')]
@install host build="local": _add
  if [[ "{{host}}" == lxc-* ]]; then \
    just _install-lxc {{host}}; \
  else \
    just _install-anywhere {{host}} {{build}}; \
  fi

@_install-lxc host:
  HOST={{host}} scripts/install-lxc.sh

@_install-anywhere host build:
  test -d .bootstrap/extra && [ "$(ls -A .bootstrap/extra)" ] \
    || { echo "Can't find the keypair. Did you bootstrap?"; exit 1; }

  nix run nixos-anywhere -- \
        --extra-files '.bootstrap/extra' \
        --build-on '{{build}}' \
        --flake '.#{{host}}' \
        root@{{host}}.lan.al

# use deploy-rs to update an existing host
[group('deployment')]
@deploy host: _add
  nix run github:serokell/deploy-rs#deploy-rs -- .#{{host}} -s

# create/edit agenix secret
[group('secrets')]
@secret secret: _add && rekey
  EDITOR=nano \
  AGENIX_REKEY_PRIMARY_IDENTITY=$(cat ./secrets/master-keys/agenix-master.pub) \
  AGENIX_REKEY_PRIMARY_IDENTITY_ONLY=true \
  nix run github:oddlama/agenix-rekey -- edit ./secrets/secrets/{{secret}}.age

# rekey all agenix secrets
[group('secrets')]
@rekey: _add
  AGENIX_REKEY_PRIMARY_IDENTITY=$(cat ./secrets/master-keys/agenix-master.pub) \
  AGENIX_REKEY_PRIMARY_IDENTITY_ONLY=true \
  nix run github:oddlama/agenix-rekey -- rekey -a

# navigate config tree
[group('tools')]
@inspect:
  nix run nixpkgs#nix-inspect -- -p .

@_add:
    git add --all
