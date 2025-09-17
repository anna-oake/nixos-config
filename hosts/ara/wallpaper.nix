{
  config,
  pkgs,
  ...
}:
{
  system.activationScripts.postActivation.text =
    let
      desktoppr = "${pkgs.desktoppr}/bin/desktoppr";
      ariane = ./assets/wallpaper-ariane.png;
      elster = ./assets/wallpaper-elster.png;
    in
    ''
      echo >&2 "Setting up wallpapers..."

      su ${config.me.username} -s /bin/sh <<'USERBLOCK'
        lines=$(${desktoppr} | awk 'END {print NR}')

        if [ "$lines" -eq 1 ]; then
            ${desktoppr} ${ariane}
        else
            ${desktoppr} 0 ${elster}
            ${desktoppr} 1 ${ariane}
        fi
      USERBLOCK
    '';
}
