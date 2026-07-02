{lix, ...} @ args: let
  inherit (lix.attrsets) attrValues listToAttrs mapAttrs;
  inherit (lix.lists) imap0;
  inherit (lix.types) isString isList;
  inherit (lix.ingestion) importModules;

  registry = {
    environments = {
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
  };

  # Helper: normalize list -> attrset
  normalizeBackends = raw:
    if isList raw
    then
      listToAttrs (map (name: {
          inherit name;
          value = {};
        })
        raw)
    else raw;

  # Helper: resolve backends from spec against registry
  resolveBackends = {
    spec,
    registry,
  }: let
    fail = msg: throw "resolveBackends: ${msg}";
    raw = (spec.interface or {}).backends or [];
    normalized = normalizeBackends raw;
    resolve = name: overrides: let
      base = registry.environments.${name} or (fail "backend '${name}' not in registry");
    in
      base // overrides // {inherit name;};
  in
    attrValues (mapAttrs resolve normalized);
in
  importModules (
    args
    // {
      base = ./.;
      path = args.path or [];
      recurse = true;
      excludes = [];
      extraArgs =
        (args.extraArgs or {})
        // {inherit registry normalizeBackends resolveBackends;};
    }
  )
