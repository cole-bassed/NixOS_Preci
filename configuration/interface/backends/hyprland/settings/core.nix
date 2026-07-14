{cfg, ...}: let
  getCmd = list: index: default:
    if list != null && (length list) > index
    then (elemAt list index).command
    else default;

  # Parse out our 3 priority tiers safely
  browser = {
    primary = getCmd cfg.browser 0 "firefox";
    secondary = getCmd cfg.browser 1 "chromium";
    tertiary = getCmd cfg.browser 2 "epiphany";
  };

  editor = {
    tty = {
      primary = getCmd cfg.editor.tty 0 "nvim";
      secondary = getCmd cfg.editor.tty 1 "hx";
      tertiary = getCmd cfg.editor.tty 2 "nano";
    };
    gui = {
      primary = getCmd cfg.editor.gui 0 "code";
      secondary = getCmd cfg.editor.gui 1 "zeditor";
      tertiary = getCmd cfg.editor.gui 2 "emacs";
    };
  };

  launcher = {
    primary = getCmd cfg.launcher 0 "wofi --show drun";
    secondary = getCmd cfg.launcher 1 "fuzzel";
    tertiary = getCmd cfg.launcher 2 "rofi -show drun";
  };

  terminal = {
    primary = getCmd cfg.terminal 0 "kitty";
    secondary = getCmd cfg.terminal 1 "foot";
    tertiary = getCmd cfg.terminal 2 "alacritty";
  };
in {
  # ╔════════════════════════════════════════════════╗
  # ╠ ENVIRONMENT & APPLICATIONS                     ╣
  # ╚════════════════════════════════════════════════╝
  env = ["XDG_CURRENT_DESKTOP,Hyprland"];
  "$MOD" = cfg.keyboard.modifier or "SUPER";

  "$browser" = browser.primary;
  "$browserAlt" = browser.secondary;
  "$browserTertiary" = browser.tertiary;

  "$editor" = editor.tty.primary;
  "$editorAlt" = editor.tty.secondary;
  "$editorTertiary" = editor.tty.tertiary;

  "$visual" = editor.gui.primary;
  "$visualAlt" = editor.gui.secondary;
  "$visualTertiary" = editor.gui.tertiary;

  "$launcher" = launcher.primary;
  "$launcherAlt" = launcher.secondary;
  "$launcherTertiary" = launcher.tertiary;

  "$terminal" = terminal.primary;
  "$terminalAlt" = terminal.secondary;
  "$terminalTertiary" = terminal.tertiary;

  # ╔════════════════════════════════════════════════╗
  # ╠ WINDOW                                         ╣
  # ╚════════════════════════════════════════════════╝
  # --------------------------------------------------
  # --> Decorations
  # --------------------------------------------------
  decoration = {
    rounding = 8;

    blur = {
      enabled = true;
      brightness = 1.0;
      contrast = 1.0;
      noise = 0.02;
      passes = 3;
      size = 8;
    };

    shadow = {
      enabled = true;
      range = 15;
      render_power = 3;
      color = "rgba(00000055)";
    };
  };

  # --------------------------------------------------
  # --> Animations
  # --------------------------------------------------
  animations = {
    enabled = true;
    animation = [
      "border, 1, 2, default"
      "fade, 1, 4, default"
      "windows, 1, 3, default, popin 80%"
      "workspaces, 1, 2, default, slide"
    ];
  };

  # --------------------------------------------------
  # --> Groups
  # --------------------------------------------------
  group = {
    groupbar = {
      font_size = 12;
      gradients = false;
    };
    "col.border_active" = "rgba(b4befeff)";
    "col.border_inactive" = "rgba(313244ff)";
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ LAYOUT & BORDERS                               ╣
  # ╚════════════════════════════════════════════════╝
  general.layout = "dwindle";

  # --------------------------------------------------
  # --> Borders & Gaps
  # --------------------------------------------------
  general = {
    gaps_in = 4;
    gaps_out = 8;
    border_size = 2;
    resize_on_border = true;
    "col.active_border" = "rgba(b4befeaf) rgba(6c7086af) 45deg";
    "col.inactive_border" = "rgba(313244ff)";
  };

  # --------------------------------------------------
  # --> Dwindle
  # --------------------------------------------------
  dwindle = {
    pseudotile = false;
    force_split = 2;
    preserve_split = true;
    default_split_ratio = 1.0;
  };

  # --------------------------------------------------
  # --> Master
  # --------------------------------------------------
  master = {
    new_status = "master";
    new_on_top = false;
    orientation = "left";
    mfact = 0.55;
    always_center_master = false;
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ MISCELLANEOUS SETTINGS                         ╣
  # ╚════════════════════════════════════════════════╝
  general = {
    sensitivity = 1.0;
    allow_tearing = false;
  };
  debug = {
    disable_logs = false;
  };
  misc = {
    disable_autoreload = false;
    force_default_wallpaper = 0;
    animate_mouse_windowdragging = false;
    vrr = 1;
  };
}
