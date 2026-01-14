{
  inputs,
  config,
  ...
}:
let
  nvidia = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.119.02";
    sha256_64bit = "sha256-gCD139PuiK7no4mQ0MPSr+VHUemhcLqerdfqZwE47Nc=";
    openSha256 = "sha256-l3IQDoopOt0n0+Ig+Ee3AOcFCGJXhbH1Q1nh1TEAHTE=";
    settingsSha256 = "sha256-sI/ly6gNaUw0QZFWWkMbrkSstzf0hvcdSaogTUoTecI=";
    usePersistenced = false;
  };
in
{
  imports = [
    inputs.self.nixosModules.default
  ];

  profiles.server.enable = true;

  hardware.graphics.enable = true;
  hardware.graphics.package = nvidia;

  environment.systemPackages = [ nvidia ];

  virtualisation.docker.enable = true;

  hardware.nvidia-container-toolkit = {
    enable = true;
    suppressNvidiaDriverAssertion = true;
  };

  lxc = {
    enable = true;
    cores = 16;
    memory = 30720;
    diskSize = 150;
    unprivileged = false;
    mounts = [
      "/storage,mp=/storage"
      "/storage-fast,mp=/storage-fast"
      "/storage-fast/attic,mp=/storage-fast/attic"
    ];
    extraConfig = ''
      dev0: /dev/nvidia0
      dev1: /dev/nvidiactl
      dev2: /dev/nvidia-uvm
      dev3: /dev/nvidia-uvm-tools
      dev4: /dev/nvidia-caps/nvidia-cap1
      dev5: /dev/nvidia-caps/nvidia-cap2
      lxc.apparmor.profile: unconfined
      lxc.cgroup2.devices.allow: a
      lxc.cap.drop:
    '';
  };

  system.stateVersion = "25.11";
}
