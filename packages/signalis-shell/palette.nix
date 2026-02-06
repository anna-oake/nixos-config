# Signalis palette, taken from the weather, radio and dirtyshot sites.
let
  colors = {
    bg = "#08090a"; # page background
    well = "#050607"; # image wells, deepest surface
    surface = "#0b0c0e"; # cards
    input = "#0b0c0d"; # inputs, selects
    raised = "#101113"; # panels, popovers, dialogs
    open = "#191d20"; # expanded sections

    line = "#383a3c"; # hairlines
    lineCard = "#444648"; # card borders
    lineStrong = "#55585a"; # input borders

    ink = "#eeeae3";
    inkBright = "#ffffff";
    soft = "#b8b9b5";
    muted = "#969899";
    dim = "#85888a";

    red = "#fa503c"; # instrumentation accent
    redDeep = "#af1717"; # active site-selector block, black text on it
    redHover = "#cd241f";
    redBorder = "#6c4843"; # idle button outline
    redDark = "#76332b"; # recording blink off-phase
    hover = "#211714"; # row hover
    selection = "#38201c"; # selected row

    yellow = "#e4c56b"; # mid elevation
    green = "#9dca83"; # high elevation
    teal = "#293632"; # progress fill
    tealOver = "#6b2620"; # progress fill past the limit

    # Supporting hues for terminals and syntax, kept dusty to sit beside the red.
    orange = "#e8804f";
    blue = "#5b9bc4";
    cyan = "#4fb6c4";
    magenta = "#c9707e";
  };

  raw = builtins.mapAttrs (_: builtins.substring 1 6) colors;
in
colors
// {
  # Hex without the leading "#", for tools that take RRGGBB[AA].
  inherit raw;

  # base16 roles for Stylix. GTK's accent comes from base0D, so the red accent
  # is reapplied on top of it rather than giving up blue everywhere else.
  base16 = with raw; {
    base00 = bg;
    base01 = raised;
    base02 = selection;
    base03 = lineStrong;
    base04 = dim;
    base05 = ink;
    base06 = soft;
    base07 = inkBright;
    base08 = red;
    base09 = orange;
    base0A = yellow;
    base0B = green;
    base0C = cyan;
    base0D = blue;
    base0E = magenta;
    base0F = redDeep;
  };
}
