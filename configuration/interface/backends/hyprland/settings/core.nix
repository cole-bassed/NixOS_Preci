{
  cfg,
  lix,
  ...
}:
(lix.attrsets.concatMapAttrs (name: value: {${"$" + name} = value;}) cfg.vars)
// {
  # ╔════════════════════════════════════════════════╗
  # ╠ ENVIRONMENT & BASE CONFIG                      ╣
  # ╚════════════════════════════════════════════════╝
  env = ["XDG_CURRENT_DESKTOP,Hyprland"];

  # ╔════════════════════════════════════════════════╗
  # ╠ WINDOW                                         ╣
  # ╚════════════════════════════════════════════════╝
  decoration = {
    rounding = 8;
    blur = {
      enabled = true;
      passes = 3;
      size = 8;
    };
    shadow = {
      enabled = true;
      range = 15;
    };
  };

  animations = {
    enabled = true;
    animation = [
      "border, 1, 2, default"
      "fade, 1, 4, default"
      "windows, 1, 3, default, popin 80%"
      "workspaces, 1, 2, default, slide"
    ];
  };

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
  general = {
    layout = "dwindle";
    gaps_in = 4;
    gaps_out = 8;
    border_size = 2;
    resize_on_border = true;
    "col.active_border" = "rgba(b4befeaf) rgba(6c7086af) 45deg";
    "col.inactive_border" = "rgba(313244ff)";
  };

  dwindle = {
    force_split = 2;
    preserve_split = true;
  };

  master = {
    new_status = "master";
    orientation = "left";
    mfact = 0.55;
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ MISCELLANEOUS SETTINGS                         ╣
  # ╚════════════════════════════════════════════════╝
  general = {
    sensitivity = 1.0;
    allow_tearing = false;
  };
  debug.disable_logs = false;
  misc = {
    disable_autoreload = false;
    force_default_wallpaper = 0;
    vrr = 1;
  };
}
