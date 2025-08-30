{
  flake,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    flake.commonModules.default
  ];

  proxmoxLXC = {
    manageNetwork = true;
    manageHostName = true;
  };

  systemd.suppressedSystemUnits = [
    "sys-kernel-debug.mount"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
