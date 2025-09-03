{
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    inputs.self.commonModules.default
    inputs.nix-things.nixosModules.default
    ./profiles
  ];

  systemd.suppressedSystemUnits = [
    "sys-kernel-debug.mount"
  ];

  proxmoxLXC.manageNetwork = true;
  networking.firewall.enable = false;

  age.identityPaths = [ "/nix-lxc/agenix_key" ];

  lxc.pve.host = "mynah.lan.ci";

  nixpkgs.hostPlatform = "x86_64-linux";
}
