{
  flake,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    flake.commonModules.default
    ./profiles
  ];

  systemd.suppressedSystemUnits = [
    "sys-kernel-debug.mount"
  ];

  proxmoxLXC.manageNetwork = true;

  age.identityPaths = [ "/nix-lxc/agenix_key" ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
