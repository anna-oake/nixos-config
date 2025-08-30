#!/usr/bin/env bash

#  _  __     _____ ____  _____ ____ ___  ____  _____ ____    _
# | | \ \   / /_ _| __ )| ____/ ___/ _ \|  _ \| ____|  _ \  | |
# | |  \ \ / / | ||  _ \|  _|| |  | | | | | | |  _| | | | | | |
# |_|   \ V /  | || |_) | |__| |__| |_| | |_| | |___| |_| | |_|
# (_)    \_/  |___|____/|_____\____\___/|____/|_____|____/  (_)

set -Eeuo pipefail
IFS=$'\n\t'

LXC_HOST="mynah.lan.ci"
LXC_HOST_DIR="/root/nix-lxc"
PUBKEY_DIR="secrets/public-keys"
BOOTSTRAP_DIR=".bootstrap"
FLAKE="${FLAKE:-.}"
NIX_FLAGS=(--extra-experimental-features nix-command --extra-experimental-features flakes)

die() { echo "error: $*" >&2; exit 1; }
confirm() { read -r -p "${1} [Y/n] " _ans; [[ ${_ans:-Y} =~ ^[Yy]$ ]]; }
need() { command -v "$1" >/dev/null || die "required command not found: $1"; }

need git; need nix; need ssh-keygen; need jq; need scp

rm -rf -- "$BOOTSTRAP_DIR"
mkdir -p "$BOOTSTRAP_DIR"

# 0) ensure we're in a clean git tree BEFORE doing anything
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repo"
git status --porcelain | grep -q . && die "working tree not clean; commit/stash changes first"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

clear

if [[ -z "${HOST:-}" ]]; then
  echo "Discovering hosts..."
  HOSTS_JSON="$(nix "${NIX_FLAGS[@]}" flake show --json "$FLAKE" 2>/dev/null)"
  mapfile -t HOSTS < <(jq -r '.nixosConfigurations | select(type=="object") | keys[]' <<<"$HOSTS_JSON" | sort)

  ((${#HOSTS[@]})) || die "no nixosConfigurations found in $FLAKE"
  clear
  echo "Choose a host to bootstrap:"
  select HOST in "${HOSTS[@]}"; do
    [[ -n "${HOST:-}" ]] && break
    echo "Invalid selection."
  done
  clear
fi

echo "Host: $HOST"
echo "Branch: $BRANCH"

if [[ $HOST == lxc-* ]]; then
  ROUTE="lxc"
  echo "This host is an LXC - will offer to upload keys"
elif nix "${NIX_FLAGS[@]}" eval "$FLAKE#nixosConfigurations.$HOST.config.environment.persistence" --json >/dev/null 2>&1; then
  ROUTE="impermanence"
  echo "This host has impermanence enabled - will adjust paths"
else
  ROUTE="normal"
fi

echo

# 2) show target branch & confirm we should proceed
confirm "Generate keys?" \
  || { echo "Aborted."; exit 0; }

echo "Generating keys..."
echo
# 3) determine route and generate host keys into bootstrap dir


umask 077
mkdir -p "$PUBKEY_DIR"

if [[ $ROUTE == "lxc" ]]; then
  SSHDIR="$BOOTSTRAP_DIR/nix-lxc/$HOST"
  mkdir -p "$SSHDIR"
  ssh-keygen -q -t ed25519 -N "" -C "$HOST" -f "$SSHDIR/agenix_key"
  PUBKEY_FILE="$SSHDIR/agenix_key.pub"

  # Upload keys to remote LXC host
  if confirm "Upload generated keys to $LXC_HOST?"; then
    ssh "root@$LXC_HOST" "mkdir -p $LXC_HOST_DIR/$HOST"
    scp "$SSHDIR/agenix_key"{,.pub} "root@$LXC_HOST:$LXC_HOST_DIR/$HOST/"
    ssh "root@$LXC_HOST" "chown -R 100000:100000 $LXC_HOST_DIR/$HOST"
  else
    echo "Skipping upload"
  fi
  echo
else
  if [[ $ROUTE == "impermanence" ]]; then
    TARGET_ETC="/persist/etc"
  else
    TARGET_ETC="/etc"
  fi
  SSHDIR="$BOOTSTRAP_DIR/extra${TARGET_ETC}/ssh"
  mkdir -p "$SSHDIR"
  ssh-keygen -q -t ed25519 -N "" -C "$HOST" -f "$SSHDIR/ssh_host_ed25519_key"
  ssh-keygen -q -t rsa    -b 4096 -N "" -C "$HOST" -f "$SSHDIR/ssh_host_rsa_key"
  chmod 0755 "$BOOTSTRAP_DIR/extra${TARGET_ETC}"
  chmod 0755 "$SSHDIR"
  PUBKEY_FILE="$SSHDIR/ssh_host_ed25519_key.pub"
fi

# 4) write/update the repo's host pubkey (for rekey) and stage it
install -m 0644 "$PUBKEY_FILE" "$PUBKEY_DIR/$HOST.pub"
git add -A

# 5) rekey using agenix-rekey
echo "Running agenix-rekey..."
nix "${NIX_FLAGS[@]}" run github:oddlama/agenix-rekey -- rekey
git add -A

# 6) show what changed and confirm committing
echo
echo "Git changes to be committed on $BRANCH:"
git status --short
confirm "Commit with message 'rekey: $HOST'?" || {
  echo
  echo "✅ Okay! Don't forget to commit later."
  exit 0
}

git commit -m "rekey: $HOST"

echo
echo "✅ Done!"
