{
  pkgs,
  config,
  unstable,
  onlyArm,
  ...
}:
{
  programs._1password.enable = true;
  programs._1password-gui =
    {
      enable = true;
      polkitPolicyOwners = [ config.me.username ];
    }
    // onlyArm {
      package = unstable._1password-gui;
    };

  environment.etc."xdg/autostart/1password.desktop".source = (
    pkgs._1password-gui + "/share/applications/1password.desktop"
  );
}
