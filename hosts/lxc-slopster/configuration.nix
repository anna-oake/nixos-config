{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./mcp.nix
    ./t3.nix
  ];

  profiles.server.enable = true;

  users.groups.slopster = { };
  users.users.slopster = {
    isSystemUser = true;
    group = "slopster";
    description = "Slop service user";
    home = "/storage-fast/slopster";
    createHome = true;
    useDefaultShell = true;
  };

  lxc = {
    enable = true;
    memory = 8192;
    mounts = [
      "/storage-fast/slopster,mp=/storage-fast/slopster"
    ];
  };

  system.stateVersion = "25.11";
}
