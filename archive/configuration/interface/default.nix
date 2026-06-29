{lix, ...} @ args:
lix.importModules (
  args
  // {
    base = ./.;
    extraArgs =
      (args.extraArgs or {})
      // {
        registry = {
          managers = {
            awesome = {
              protocol = "x11";
              session = "awesome";
              login = "lightdm";
            };

            i3 = {
              protocol = "x11";
              session = "none+i3";
              login = "lightdm";
            };

            qtile = {
              protocol = "x11";
              session = "qtile";
              login = "lightdm";
            };

            xmonad = {
              protocol = "x11";
              session = "xmonad";
              login = "lightdm";
            };

            hyprland = {
              protocol = "wayland";
              session = "hyprland";
              login = "regreet";
              uwsm = true;
            };

            labwc = {
              protocol = "wayland";
              session = "labwc";
              login = "regreet";
            };

            mango = {
              protocol = "wayland";
              session = "mango";
              login = "regreet";
            };

            niri = {
              protocol = "wayland";
              session = "niri";
              login = "regreet";
              needsXwaylandSatellite = true;
            };

            river = {
              protocol = "wayland";
              session = "river";
              login = "regreet";
            };

            sway = {
              protocol = "wayland";
              session = "sway";
              login = "regreet";
              uwsm = true;
            };

            wayfire = {
              protocol = "wayland";
              session = "wayfire";
              login = "regreet";
            };
          };

          desktops = {
            cinnamon = {
              protocol = "x11";
              session = "cinnamon";
              login = "lightdm";
            };

            xfce = {
              protocol = "x11";
              session = "xfce";
              login = "lightdm";
            };

            gnome = {
              protocol = "wayland";
              session = "gnome";
              login = "gdm";
            };

            plasma = {
              protocol = "wayland";
              session = "plasma";
              login = "sddm";
            };
          };
        };
      };
  }
)
