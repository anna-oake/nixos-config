{ inputs, pkgs, ... }:
{
  imports = [ inputs.nixun.nixosModules.redmi-pad-se ];

  nixpkgs.hostPlatform = "aarch64-linux";
  hardware.redmi-pad-se = {
    enable = true;
    panelVariant = "m84-36-02-0a";
  };

  boot.kernelParams = [
    "regulator_ignore_unused"
    "g_ether.host_addr=ee:6c:b4:46:c0:fe"
    "g_ether.dev_addr=da:d9:74:25:fa:b1"
  ];
  hardware.deviceTree.overlays = [
    {
      name = "xun-native-display";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "xiaomi,xun";
        };

        &framebuffer0 {
          status = "disabled";
        };
      '';
    }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_XUN";
    fsType = "ext4";
    autoResize = true;
  };

  networking.interfaces.usb0.ipv4.addresses = [
    {
      address = "172.16.42.1";
      prefixLength = 24;
    }
  ];
  boot.kernelModules = [ "g_ether" ];

  environment.systemPackages = [ pkgs.qbootctl ];
}
