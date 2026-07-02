{lix, ...} @ args: let
  inherit (lix.attrsets) isAttrs optionalAttrs;
  inherit (lix.types) isString;
  inherit (lix.lists) imap0;
  inherit (lix.ingestion) importModules;
in
  importModules (
    args
    // {
      base = ./.;
      path = args.path or [];
      recurse = true;
      excludes = ["frontend"];
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

          # Resolve a host/user's declared `interface.environments` (a list of
          # backend names, optionally with per-entry overrides) against the
          # registry above. First entry is the primary environment.
          #
          #   interface.environments = [ "hyprland" "niri" ];
          #   interface.environments = [ { name = "hyprland"; greeter = "regreet"; } ];
          resolveEnvironments = {
            host,
            registry,
          }: let
            hostName = host.name or "unknown";
            fail = msg: throw "api/hosts/${hostName}: ${msg}";
            raw = (host.interface or {}).environments or [];

            resolve = idx: entry: let
              name =
                if isString entry
                then entry
                else entry.name or (fail "environment at index ${toString idx} missing 'name'");
            in
              {
                inherit name;
                priority = idx;
              }
              // optionalAttrs (isAttrs entry) (removeAttrs entry ["name"])
              (
                registry.environments.${name}
                or (fail "environment '${name}' is not a known backend in registry.environments")
              );
          in
            imap0 resolve raw;
        };
    }
  )
