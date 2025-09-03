#!/usr/bin/env bash
set -Eeuo pipefail
FLAKE="${FLAKE:-.}"
NIX_FLAGS=(--extra-experimental-features nix-command --extra-experimental-features flakes)

bold=$(tput bold)
normal=$(tput sgr0)

die() { echo "error: $*" >&2; exit 1; }
confirm() { read -r -p "${1} [Y/n] " _ans; [[ ${_ans:-Y} =~ ^[Yy]$ ]]; }
need() { command -v "$1" >/dev/null || die "required command not found: $1"; }
wipe() { clear; echo "${bold}Host: $HOST${normal}"; echo; }
ask_pct_id() {
  local prompt="$1" default="$2" _ans num

  read -r -p "${prompt} [${default}] " _ans
  num="${_ans:-$default}"

  # must be integer
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    die "Not a valid number: $num"
  fi

  echo "$num"
}

need nix; need jq; need scp; need awk

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repo"
# git status --porcelain | grep -q . && die "working tree not clean; commit/stash changes first"

wipe

echo "Loading..."

LXC_STORAGE="$(nix "${NIX_FLAGS[@]}" eval "$FLAKE#nixosConfigurations.$HOST.config.lxc.storageName" --raw)"
LXC_JSON="$(nix "${NIX_FLAGS[@]}" eval "$FLAKE#nixosConfigurations.$HOST.config.lxc.pve" --json)"
LXC_HOST=$(jq -r '.host' <<<"$LXC_JSON")
[[ -n "$LXC_HOST" && "$LXC_HOST" != "null" ]] || die "LXC_HOST is empty or null"
LXC_HOST_TARBALL_DIR=$(jq -r '.tarballPath' <<<"$LXC_JSON")
[[ -n "$LXC_HOST_TARBALL_DIR" && "$LXC_HOST_TARBALL_DIR" != "null" ]] || die "LXC_HOST_TARBALL_DIR is empty or null"

wipe
echo "Building tarball..."

BUILD_OUT="$(nix build "${NIX_FLAGS[@]}" "$FLAKE#nixosConfigurations.$HOST.config.system.build.tarball" --no-link --print-out-paths)"

shopt -s nullglob
matches=("$BUILD_OUT"/tarball/vzdump-*.tar.zst)
(( ${#matches[@]} == 1 )) || die "No tarball found in $BUILD_OUT"
TARBALL="${matches[0]}"
TARBALL_NAME="${TARBALL##*/}"

wipe
echo "Tarball is ready."
echo
confirm "Upload to $LXC_HOST:$LXC_HOST_TARBALL_DIR/$TARBALL_NAME?" \
  || { echo "Aborted."; exit 0; }

scp $TARBALL "root@$LXC_HOST:$LXC_HOST_TARBALL_DIR/"

wipe
echo "Uploaded. Please wait..."

PCT_LIST="$(ssh root@$LXC_HOST "pct list")"
NEXT_ID="$(ssh root@$LXC_HOST "/usr/bin/pvesh get /cluster/nextid")"

wipe
echo "${bold}Current LXC list on $LXC_HOST:${normal}"
echo "$PCT_LIST"
echo

echo "${bold}Pick an ID for the new LXC.${normal}"
echo "${bold}Enter 0${normal} - operation will be aborted"
echo "${bold}Enter an existing one${normal} - the old container will be ${bold}DESTROYED${normal} and replaced! ${bold}RISK OF DATA LOSS!${normal}"
echo "${bold}Enter nothing${normal} - auto-generated ID $NEXT_ID will be used"
echo

PCT_ID="$(ask_pct_id "Which ID to use for $HOST?" $NEXT_ID)"
(( PCT_ID > 0 )) || { echo "Aborted."; exit 0; }

wipe

read -r PCT_EXISTS PCT_RUNNING PCT_NAME < <(
  awk -v id="$PCT_ID" '
    NR==1 { next }                                   # skip header
    $1==id { print 1, ($2=="running")?1:0, $NF; f=1; exit }
    END { if (!f) print 0, 0, "" }
  ' <<< "$PCT_LIST"
)

NEW_MAC=""

if (( PCT_EXISTS ));  then
    OLD_PCT_CONFIG="$(ssh root@$LXC_HOST "pct config $PCT_ID")"
    OLD_MAC=""
    [[ $OLD_PCT_CONFIG =~ hwaddr=([[:xdigit:]]{2}(:[[:xdigit:]]{2}){5})(,|$) ]] && OLD_MAC="${BASH_REMATCH[1]}"

    if [ -n "$OLD_MAC" ]; then
        echo "Found MAC ${bold}${OLD_MAC}${normal} in the existing LXC $PCT_NAME ($PCT_ID)."
        echo "Say Y to reuse the old MAC in the new LXC."
        echo "Say n to generate a new random MAC."
        echo
        if confirm "Reuse the old MAC from $PCT_NAME ($PCT_ID)?"; then
            NEW_MAC="$OLD_MAC"
        fi
    fi

    wipe
    echo "If you proceed, the existing LXC $PCT_NAME ($PCT_ID) and its bootdisk will be ${bold}DESTROYED${normal}!"
    echo "It is now ${bold}running${normal}, so it will be stopped before destruction."
    echo

    confirm "Proceed to destroy the existing LXC $PCT_NAME ($PCT_ID)?" \
      || { echo "Aborted."; exit 0; }
fi

UNIQUE="--unique"
if [ -n "$NEW_MAC" ]; then
    UNIQUE=""
fi

wipe
if (( PCT_RUNNING )); then
    echo "Stopping the existing LXC $PCT_NAME ($PCT_ID)..."
    ssh root@$LXC_HOST "pct stop $PCT_ID"
fi

echo "Creating on $LXC_HOST with ID $PCT_ID..."
RESTORE_OUT="$(ssh root@$LXC_HOST "pct restore $PCT_ID $LXC_HOST_TARBALL_DIR/$TARBALL_NAME $UNIQUE --force --storage $LXC_STORAGE")"
if [ -n "$NEW_MAC" ]; then
    echo "Setting the MAC address to $NEW_MAC..."
    PCT_CONFIG="$(
      ssh root@"$LXC_HOST" \
        "set -e; f=/etc/pve/lxc/${PCT_ID}.conf; [ -f \"\$f\" ]; sed -i '0,/00:00:00:00:00:00/s//${NEW_MAC}/' \"\$f\"; cat \"\$f\""
    )"
else
    PCT_CONFIG="$(ssh root@$LXC_HOST "pct config $PCT_ID")"
fi

wipe
echo "${bold}Successfully created as $PCT_ID!${normal}"
echo
echo "Resulting config:"

echo "$PCT_CONFIG"
echo
echo
confirm "Would you like to start the new LXC $PCT_NAME ($PCT_ID)?" \
  || { echo; echo "Done! You can start the LXC manually."; exit 0; }
ssh root@$LXC_HOST "pct start $PCT_ID"
echo
echo "Done!"
