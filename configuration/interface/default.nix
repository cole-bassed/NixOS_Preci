{lix, ...} @ args: let
  inherit (lix.ingestion) mkModules;
in
  mkModules (
    args
    // {
      base = ./.;
      path = args.path or [];
      recurse = true;
      excludes = [
        # "backends"
        "frontend"
        "protocol"
        "session"
      ];
      data = {
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
        hyprland = {
          protocol = "wayland";
          greeter = "dank-material-shell";
          frontend = "dank-material-shell";
          uwsm = true;
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
        niri = {
          protocol = "wayland";
          greeter = "dank-material-shell";
          frontend = "dank-material-shell";
          needsXwaylandSatellite = true;
        };
        river = {
          protocol = "wayland";
          greeter = "dank-material-shell";
          frontend = null;
        };
        sway = {
          protocol = "wayland";
          greeter = "dank-material-shell";
          frontend = "dank-material-shell";
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
        gnome = {
          protocol = "wayland";
          greeter = "gdm";
          frontend = "gnome-shell";
        };
        cosmic = {
          protocol = "wayland";
          greeter = "cosmic-greeter";
          frontend = "cosmic-shell";
        };
        plasma = {
          protocol = "wayland";
          greeter = "plasma-login-manager";
          frontend = "plasma";
        };
      };
    }
  )
