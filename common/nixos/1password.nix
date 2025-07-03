{
  pkgs,
  config,
  ...
}:
{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ config.me.username ];
  };

  # append `--js-flags="--nodecommit_pooled_pages"` to Exec line in 1password.desktop 

  environment.etc."xdg/autostart/1password.desktop".source = (
    pkgs._1password-gui + "/share/applications/1password.desktop"
  );
}
