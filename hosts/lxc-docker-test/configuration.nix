{
  inputs,
  config,
  ...
}:
let
  nvidia = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.119.02";
    sha256_64bit = "sha256-Bh5I4R/lUiMglYEdCxzqm3GgayQNYFB0/yJ/zgYoeYw=";
    openSha256 = "sha256-8/7ZrcwBMgrBtxebYtCcH5A51sexAxXTCY00LElZz08=";
    settingsSha256 = "sha256-lx1WZHsW7eKFXvi03dAML667C5glEn63Tuiz3T867nY=";
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
