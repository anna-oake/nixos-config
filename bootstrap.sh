#!/usr/bin/env bash

#  _  __     _____ ____  _____ ____ ___  ____  _____ ____    _
# | | \ \   / /_ _| __ )| ____/ ___/ _ \|  _ \| ____|  _ \  | |
# | |  \ \ / / | ||  _ \|  _|| |  | | | | | | |  _| | | | | | |
# |_|   \ V /  | || |_) | |__| |__| |_| | |_| | |___| |_| | |_|
# (_)    \_/  |___|____/|_____\____\___/|____/|_____|____/  (_)

set -Eeuo pipefail
IFS=$'\n\t'
shopt -s inherit_errexit 2>/dev/null || true

PUBKEY_DIR="secrets/public-keys"        # where your host pubkeys live in the repo
BOOTSTRAP_DIR=".bootstrap"              # where we stage files for nixos-anywhere --extra-files
FLAKE="${FLAKE:-.}"                     # flake path (default: current repo)
NIX_FLAGS=(--extra-experimental-features nix-command --extra-experimental-features flakes)

die() { echo "error: $*" >&2; exit 1; }
confirm() { read -r -p "${1} [y/N] " _ans; [[ ${_ans:-} =~ ^[Yy]$ ]]; }
need() { command -v "$1" >/dev/null || die "required command not found: $1"; }
cleanup_on_err() { echo "❌ failed at line $LINENO"; exit 1; }
trap cleanup_on_err ERR

need git; need nix; need ssh-keygen; need jq

rm -rf -- "$BOOTSTRAP_DIR"
mkdir -p "$BOOTSTRAP_DIR"

# 0) ensure we're in a clean git tree BEFORE doing anything
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repo"
git update-index -q --refresh
git diff --quiet       || die "working tree has unstaged changes"
git diff --cached --quiet || die "index has staged but uncommitted changes"
[[ -z "$(git ls-files --others --exclude-standard)" ]] || die "untracked files present; commit/stash them first"

# 1) discover hostnames from flake and pick one
echo "Evaluating nixosConfigurations from flake: $FLAKE ..."
HOSTS_JSON="$(nix "${NIX_FLAGS[@]}" flake show --json "$FLAKE" 2>/dev/null)"
mapfile -t HOSTS < <(jq -r '.nixosConfigurations | select(type=="object") | keys[]' <<<"$HOSTS_JSON" | sort)

((${#HOSTS[@]})) || die "no nixosConfigurations found in $FLAKE"
echo "Available hosts:"
select HOST in "${HOSTS[@]}"; do
  [[ -n "${HOST:-}" ]] && break
  echo "Invalid selection."
done
echo "→ selected host: $HOST"

# 2) show target branch & confirm we should proceed
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Current branch: $BRANCH"
confirm "Proceed to generate host keys for '$HOST', rekey secrets, and prepare a commit on '$BRANCH'?" \
  || { echo "Canceled before making any changes."; exit 0; }

# 3) generate host keys into bootstrap dir
# Decide where to stage /etc for the target (impermanence?)
TARGET_ETC="/etc"
read -r -p "Will the target use impermanence (i.e., persist /etc under /persist)? [y/N] " _ans
if [[ ${_ans:-} =~ ^[Yy]$ ]]; then
  TARGET_ETC="/persist/etc"
fi

# Stage path for SSH host keys under the chosen etc/
SSHDIR="$BOOTSTRAP_DIR/extra${TARGET_ETC}/ssh"
umask 077
mkdir -p "$SSHDIR" "$PUBKEY_DIR"

for k in ssh_host_ed25519_key ssh_host_rsa_key; do
  if [[ -e "$SSHDIR/$k" ]]; then
    confirm "Key $SSHDIR/$k exists. Overwrite?" || die "aborting to avoid overwriting $SSHDIR/$k"
  fi
done

ssh-keygen -q -t ed25519 -N "" -C "$HOST" -f "$SSHDIR/ssh_host_ed25519_key"
ssh-keygen -q -t rsa    -b 4096 -N "" -C "$HOST" -f "$SSHDIR/ssh_host_rsa_key"

# 4) write/update the repo's host pubkey (for rekey) and stage it
install -m 0644 "$SSHDIR/ssh_host_ed25519_key.pub" "$PUBKEY_DIR/$HOST.pub"
git add -A

# 5) rekey using agenix-rekey
echo "Running agenix-rekey..."
nix "${NIX_FLAGS[@]}" run github:oddlama/agenix-rekey -- rekey

# 6) show what changed and confirm committing
echo
echo "Git changes to be committed on $BRANCH:"
git status --short
confirm "Commit with message 'rekey: $HOST'?" || {
  echo "Not committing. Reverting any changes made by this script..."
  git reset --hard -q HEAD
  rm -f "$PUBKEY_DIR/$HOST.pub"
  echo "Canceled. Your repo is clean."
  exit 0
}

git add -A
git commit -m "rekey: $HOST"

echo
echo "✅ Ready. Your pre-generated host keys live in: $SSHDIR"
echo "   Next step (on your Mac):"
echo "     nix run github:nix-community/nixos-anywhere -- \\"
echo "       --extra-files '$BOOTSTRAP_DIR/extra' \\"
echo "       --flake '$FLAKE#$HOST' root@<ip-or-dns>"
