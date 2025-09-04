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
export AGENIX_REKEY_PRIMARY_IDENTITY_ONLY := "true"
export AGENIX_REKEY_PRIMARY_IDENTITY := `cat ./secrets/master-keys/agenix-master.pub`

#
#  personal recipes go below
#
