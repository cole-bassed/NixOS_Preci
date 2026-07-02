{lix, ...} @ args: let
  inherit (lix.attrsets) attrValues listToAttrs mapAttrs;
  inherit (lix.lists) imap0;
  inherit (lix.types) isString isList;
  inherit (lix.modules) mkModules;
in
  mkModules (
    args
    // {
      base = ./.;
      path = args.path or [];
      recurse = true;
      excludes = [];
      extraArgs =
        (args.extraArgs or {})
        // {
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

          # Resolve a host/user's declared backends against the registry.
          # Accepts either a list of names or an attrset of { name = { ... }; }.
          # First entry is primary. Returns a list of resolved env records.
          resolveEnvironments = {
            host,
            registry,
          }: let
            hostName = host.name or "unknown";
            fail = msg: throw "api/hosts/${hostName}: ${msg}";
            raw = (host.interface or {}).backends or [];
            normalized =
              if isList raw
              then
                listToAttrs (
                  imap0 (idx: entry: {
                    name =
                      if isString entry
                      then entry
                      else entry.name or (fail "backend at index ${toString idx} missing 'name'");
                    value =
                      if isString entry
                      then {}
                      else removeAttrs entry ["name"];
                  })
                  raw
                )
              else raw;

            resolve = name: overrides: let
              base = registry.environments.${name}
                or (fail "backend '${name}' is not a known environment in registry.environments");
            in
              base // overrides // {inherit name;};
          in
            attrValues (mapAttrs resolve normalized);
        };
    }
  )
