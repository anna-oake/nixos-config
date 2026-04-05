{
  config,
  lib,
  ...
}:
{
  imports = [
    ./apps.nix
    ./system-defaults.nix
  ];

  config = lib.mkIf config.profiles.workstation.enable {
    environment.systemPath = [
      "/Users/${config.me.username}/.local/bin"
    ];

    launchd.daemons.nix-daemon.environment = {
      SSH_AUTH_SOCK = "/Users/anna/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

    remoteBuilders = {
      protocol = "ssh";
      machines = {
        gratis = {
          enable = true;
          sshUser = "root";
        };
        lxc-builder-kitezh = {
          enable = true;
          sshUser = "root";
        };
      };
    };
  };
}
