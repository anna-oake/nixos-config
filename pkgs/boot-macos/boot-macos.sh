#!/usr/bin/env bash
set -euxo pipefail

sudo asahi-bless --set-boot "macOS" --yes

sudo reboot