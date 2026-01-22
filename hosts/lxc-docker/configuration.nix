{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.docker = {
    enable = true;
    enableNvidiaSupport = true;

    portainer = {
      enable = true;
      traefikIntegration.entrypoint = "lan";
    };
  };

  lxc = {
    enable = true;
    cores = 16;
    memory = 30720;
    diskSize = 80;
    mounts = [
      "/storage,mp=/storage"
      "/storage-fast,mp=/storage-fast"
      "/storage-fast/attic,mp=/storage-fast/attic"
      "/storage-fast/docker,mp=/var/lib/docker/volumes"
    ];
    nvidia.enable = true;
  };

  system.stateVersion = "25.11";
}
