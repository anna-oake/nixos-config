_: {
  services.aerospace = {
    enable = false;
    settings = {
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      accordion-padding = 0;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      key-mapping.preset = "qwerty";
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      gaps = {
        inner.horizontal = 6;
        inner.vertical = 6;
        outer.left = 6;
        outer.bottom = 52; # ubersicht stuff
        outer.top = 6;
        outer.right = 6;
      };

      mode.main.binding = {
        alt-slash = "layout tiles horizontal accordion horizontal";

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";

        alt-shift-minus = "resize smart -100";
        alt-shift-equal = "resize smart +100";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
        alt-shift-semicolon = "mode service";

        alt-tab = "workspace-back-and-forth";
        alt-equal = "balance-sizes";
      };

      mode.service.binding = {
        esc = [
          "reload-config"
          "mode main"
        ];
        space = [
          "layout floating tiling"
          "mode main"
        ];
      };

      on-window-detected = [
        {
          "if".app-name-regex-substring = "notes|finder|messages|system settings";
          run = "layout floating";
        }
        {
          "if".app-name-regex-substring = "mail|calendar";
          run = "move-node-to-workspace 4";
        }
      ];
    };
  };
}
