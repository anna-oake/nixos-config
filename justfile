import? 'shared.just'

@_default: update-shared
    just --list  --unsorted

# update shared.just from oake/nix-things
@update-shared:
    curl -fsSO https://raw.githubusercontent.com/oake/nix-things/refs/heads/main/shared.just

#
#  settings
#

landomain := "lan.al"
export EDITOR := "nano"

#
#  personal recipes go below
#

# run darwin-rebuild switch
[group('tools')]
@rebuild: _add
    sudo darwin-rebuild switch
