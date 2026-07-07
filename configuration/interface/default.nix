{
  lix,
  top,
  ...
} @ args: let
  inherit (lix.ingestion) mkModules;
  inherit (lix.registry) selectionOf;
  registry = {
    awesome = {
      protocol = "x11";
      greeter = "lightdm";
      frontend = null;
    };
    i3 = {
      protocol = "x11";
      session = "none+i3";
      greeter = "lightdm";
      frontend = null;
    };
    qtile = {
      protocol = "x11";
      greeter = "lightdm";
      frontend = null;
    };
    xmonad = {
      protocol = "x11";
      greeter = "lightdm";
      frontend = null;
    };

    labwc = {
      protocol = "wayland";
      greeter = "dank-material-shell";
      frontend = null;
    };
    mango = {
      protocol = "wayland";
      greeter = "dank-material-shell";
      frontend = "caelestia";
    };
    river = {
      protocol = "wayland";
      greeter = "dank-material-shell";
      frontend = null;
    };
    wayfire = {
      protocol = "wayland";
      greeter = "dank-material-shell";
      frontend = null;
    };
    cinnamon = {
      protocol = "x11";
      greeter = "lightdm";
      frontend = null;
    };
    xfce = {
      protocol = "x11";
      greeter = "lightdm";
      frontend = null;
    };
    plasma = {
      protocol = "wayland";
      greeter = "plasma-login-manager";
      frontend = "plasma";
    };
    hyprland = {
      protocol = "wayland";
      greeter = "dank-material-shell";
      frontend = "dank-material";
    };
    niri = {
      protocol = "wayland";
      greeter = "dank-material-shell";
      frontend = "dank-material";
      needsXwaylandSatellite = true;
    };
    sway = {
      protocol = "wayland";
      greeter = "dank-material-shell";
      frontend = "dank-material";
    };
    gnome = {
      protocol = "wayland";
      greeter = "gdm";
      frontend = "gnome";
    };
    cosmic = {
      protocol = "wayland";
      greeter = "cosmic-greeter";
      frontend = "cosmic";
    };
  };
  selection = spec: selectionOf {inherit top registry spec;};
in
  mkModules (
    args
    // {
      base = ./.;
      path = args.path or ["interface"];
      recurse = true;
      declareRegistry = true;
      extraArgs = {inherit registry selection;};
    }
  )
