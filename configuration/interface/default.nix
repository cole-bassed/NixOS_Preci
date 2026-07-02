{
  lix,
  top,
  ...
} @ args: let
  inherit (lix.attrsets) attrValues listToAttrs mapAttrs;
  inherit (lix.types) isList;
  inherit (lix.ingestion) importModules;

  registry = {
    awesome = {
      protocol = "x11";
      session = "awesome";
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
      session = "qtile";
      greeter = "lightdm";
      frontend = null;
    };
    xmonad = {
      protocol = "x11";
      session = "xmonad";
      greeter = "lightdm";
      frontend = null;
    };
    hyprland = {
      protocol = "wayland";
      session = "hyprland";
      greeter = "dank-material-shell";
      uwsm = true;
      frontend = "dank-material-shell";
    };
    labwc = {
      protocol = "wayland";
      session = "labwc";
      greeter = "dank-material-shell";
      frontend = null;
    };
    mango = {
      protocol = "wayland";
      session = "mango";
      greeter = "dank-material-shell";
      frontend = "caelestia";
    };
    niri = {
      protocol = "wayland";
      session = "niri";
      greeter = "dank-material-shell";
      needsXwaylandSatellite = true;
      frontend = "dank-material-shell";
    };
    river = {
      protocol = "wayland";
      session = "river";
      greeter = "dank-material-shell";
      frontend = null;
    };
    sway = {
      protocol = "wayland";
      session = "sway";
      greeter = "dank-material-shell";
      uwsm = true;
      frontend = "dank-material-shell";
    };
    wayfire = {
      protocol = "wayland";
      session = "wayfire";
      greeter = "dank-material-shell";
      frontend = null;
    };
    cinnamon = {
      protocol = "x11";
      session = "cinnamon";
      greeter = "lightdm";
      frontend = null;
    };
    xfce = {
      protocol = "x11";
      session = "xfce";
      greeter = "lightdm";
      frontend = null;
    };
    gnome = {
      protocol = "wayland";
      session = "gnome";
      greeter = "gdm";
      frontend = "gnome-shell";
    };
    cosmic = {
      protocol = "wayland";
      session = "cosmic";
      greeter = "cosmic-greeter";
      frontend = "cosmic-shell";
    };
    plasma = {
      protocol = "wayland";
      session = "plasma";
      greeter = "plasma-login-manager";
      frontend = "plasma";
    };
  };

  normalize = raw:
    if isList raw
    then
      listToAttrs (map (name: {
          inherit name;
          value = {};
        })
        raw)
    else raw;

  resolve = {
    spec,
    registry,
  }: let
    ctx = "${top}.interface.resolve";
    raw = (spec.interface or {}).backends or [];
    normalized = normalize raw;
    resolved = name: overrides:
      (registry.${name} or (throw "${ctx}: '${name}' not in registry"))
      // overrides // {inherit name;};
  in
    attrValues (mapAttrs resolved normalized);

  cfgOf = spec:
    map (entry: entry.name) (resolve {inherit registry spec;});
in
  importModules (
    args
    // {
      base = ./.;
      path = args.path or [];
      recurse = true;
      excludes = ["backends" "frontend" "protocol" "session"];
      inherit registry;
      extraArgs = (args.extraArgs or {}) // {inherit registry;};
    }
  )
