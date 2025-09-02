{
  pkgs,
  config,
  lib,
  ...
}:
let
  sftpShell = pkgs.writeShellScriptBin "sftpgo-subsys" ''
    exec ${pkgs.sftpgo}/bin/sftpgo startsubsys -j
  '';
in
{
  config = lib.mkIf config.lxc.profiles.share.enable {
    users.users = lib.genAttrs (builtins.attrNames config.lxc.profiles.share.users) (name: {
      shell = "${sftpShell}/bin/sftpgo-subsys";
    });
    services.openssh.sftpServerExecutable = "${sftpShell}/bin/sftpgo-subsys";
  };
}
