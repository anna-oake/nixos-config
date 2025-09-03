{
  lib,
  hostName,
  config,
  ...
}:
{
  options.lxc = {
    cores = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Number of cores to allocate to the container";
    };
    memory = lib.mkOption {
      type = lib.types.int;
      default = 1024;
      description = "Amount of memory to allocate to the container in MB";
    };
    swap = lib.mkOption {
      type = lib.types.int;
      default = 512;
      description = "Amount of swap space to allocate to the container in MB";
    };
    diskSize = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Size of the container's disk in GB";
    };
    storageName = lib.mkOption {
      type = lib.types.str;
      default = "lxc";
      description = "Name of the storage pool to use for the container";
    };
    network = lib.mkOption {
      type = lib.types.str;
      default = "vmbr0";
      description = "Name of the network bridge to use for the container";
    };
    unprivileged = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run the container in an unprivileged mode";
    };
    features = lib.mkOption {
      type = lib.types.listOf (lib.types.str);
      default = [ ];
      description = "List of features to enable for the container";
    };
    mounts = lib.mkOption {
      type = lib.types.listOf (lib.types.str);
      default = [ ];
      description = "List of mounts to configure for the container";
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional configuration options to set for the container";
    };
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically start the container on boot";
    };
    pve = lib.mkOption {
      type = lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = "The hostname of the PVE host to install the container to";
          };
          tarballPath = lib.mkOption {
            type = lib.types.str;
            default = "/rpool/nix-tarballs/dump";
            description = "The path on the PVE host where the vzdump tarballs are stored";
          };
          keypairPath = lib.mkOption {
            type = lib.types.str;
            default = "/root/nix-lxc/${hostName}";
            description = "The path on the PVE host where the agenix keypair is stored";
          };
        };
      };
      description = "Configuration options for the Proxmox VE host for this container";
    };
  };
  config = {
    lxc.mounts = [ "${config.lxc.pve.keypairPath},mp=/nix-lxc,ro=1" ];
    lxc.features = [ "nesting" ];
  };
}
