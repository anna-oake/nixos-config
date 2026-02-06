{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  c = pkgs.signalis-shell.palette;
  crt = builtins.readFile ../crt.frag;
in
{
  # Stylix only adds its home-manager module on hosts where it is enabled.
  config = lib.mkIf config.profiles.workstation.niri.enable (
    lib.optionalAttrs (options ? stylix) {
      stylix.targets = {
        # Keep the fonts and opacity set in the personal profile; take colors only.
        ghostty.fonts.enable = false;
        ghostty.opacity.enable = false;
        zed.fonts.enable = false;

        # Stylix derives GTK's accent from base0D (blue); put the red back, and
        # square everything off like the shell.
        gtk.extraCss = ''
          @define-color accent_color ${c.red};
          @define-color accent_bg_color ${c.redDeep};
          @define-color accent_fg_color #000000;
          @define-color destructive_bg_color ${c.redDeep};
          @define-color destructive_fg_color #000000;
          @define-color warning_color ${c.yellow};
          @define-color headerbar_bg_color ${c.bg};
          @define-color headerbar_border_color ${c.line};
          @define-color borders ${c.line};

          * { border-radius: 0; }
          selection { background-color: ${c.red}; color: ${c.bg}; }
          row:selected, treeview.view:selected, .view:selected {
            background-color: ${c.selection};
            color: ${c.inkBright};
            box-shadow: inset 2px 0 ${c.red};
          }
          *:focus-visible { outline-color: ${c.red}; }
        '';
      };

    }
    // {
      # Stylix's gnome target sets the scheme and fonts; libadwaita also wants an accent.
      dconf.settings."org/gnome/desktop/interface".accent-color = "red";
      # No minimise/maximise/close in client-side titlebars (Helium, GTK apps); niri has binds.
      dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "";

      programs.niri.settings = {
        hotkey-overlay.skip-at-startup = true;

        # The shell's wallpaper stays visible behind the zoomed-out overview.
        layer-rules = [
          {
            matches = [ { namespace = "^wallpaper$"; } ];
            place-within-backdrop = true;
          }
        ];

        overview.backdrop-color = c.bg;

        layout = {
          # Hairline frames: red on the focused window, grey on the rest.
          focus-ring.enable = false;
          border = {
            enable = true;
            width = 1;
            active.color = c.red;
            inactive.color = c.line;
            urgent.color = c.yellow;
          };
          shadow.enable = false;

          tab-indicator = {
            width = 2;
            gap = 4;
            active.color = c.red;
            inactive.color = c.line;
            urgent.color = c.yellow;
          };

          insert-hint.display.color = "${c.red}55";
        };

        animations = {
          window-open = {
            kind.easing = {
              duration-ms = 280;
              curve = "linear";
            };
            custom-shader = crt + ''
              vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                  return crt_beam(coords_geo, size_geo, niri_clamped_progress);
              }
            '';
          };
          window-close = {
            kind.easing = {
              duration-ms = 220;
              curve = "linear";
            };
            custom-shader = crt + ''
              vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                  return crt_beam(coords_geo, size_geo, 1.0 - niri_clamped_progress);
              }
            '';
          };
        };
      };
    }
  );
}
