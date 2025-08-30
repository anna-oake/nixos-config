Largely inspired by https://github.com/maeve-oake/nixos-config

## how to do a fresh install
0. (laptop) plug in yubikey
1. (laptop) run `just bootstrap` and pick a host
2. push, wait until everything is built and cached
3. (target) boot into NixOS live environment from PXE
4. (laptop) run `just install {target-host}`

## how to create a new LXC
0. create a host named `lxc-{whatever}`
1. configure, make sure to import `flake.lxcModules.default`, commit
2. run `just bootstrap` and pick the host
3. push, wait until tarball is built and uploaded to mynah
4. restore the tarball (check MAC/DHCP/DNS)

## how to update a host remotely
0. (laptop) run `just deploy {target-host}`