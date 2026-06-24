{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) asAttrs namesOf valuesOf;
  inherit (lix.lists) elem maps optionals;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) enum listOf;

  setOf = list: namesOf (asAttrs list);

  get = user:
    (user.interface or {}).environment or {};

  merge = specs: {
    managers = setOf (maps (spec: spec.managers or []) specs);
    desktops = setOf (maps (spec: spec.desktops or []) specs);
  };

  spec = let
    host' = host.interface.environment or {};
    users = maps (user: [get user]) (valuesOf (getInteractiveUsers host));

    managers = {
      x11 = [
        "awesome"
        "i3"
        "qtile"
        "xmonad"
      ];

      wayland = [
        "hyprland"
        "labwc"
        "mango"
        "niri"
        "river"
        "sway"
        "wayfire"
      ];
    };

    desktops = {
      x11 = [
        "cinnamon"
        "xfce"
      ];

      wayland = [
        "gnome"
        "plasma"
      ];
    };
  in {
    inherit managers desktops;

    all = {
      managers = managers.x11 ++ managers.wayland;
      desktops = desktops.x11 ++ desktops.wayland;
      x11 = managers.x11 ++ desktops.x11;
      wayland = managers.wayland ++ desktops.wayland;
    };

    host = host';
    inherit users;

    core = merge ([host'] ++ users);

    home = user: let
      user' = get user;
    in
      merge [host' user'];
  };

  opts = {
    base = preset: cfg: {
      managers = mkOption {
        type = listOf (enum spec.all.managers);
        default = preset.managers;
        description = "Enabled standalone compositors/window managers.";
      };

      desktops = mkOption {
        type = listOf (enum spec.all.desktops);
        default = preset.desktops;
        description = "Enabled full desktop environments.";
      };

      hyprland = {
        enable =
          mkEnableOption "Hyprland compositor"
          // {default = elem "hyprland" cfg.managers;};

        withUWSM =
          mkEnableOption "launching Hyprland through UWSM"
          // {default = true;};
      };

      niri = {
        enable =
          mkEnableOption "Niri compositor"
          // {default = elem "niri" cfg.managers;};
      };

      sway = {
        enable =
          mkEnableOption "Sway compositor"
          // {default = elem "sway" cfg.managers;};
      };

      river = {
        enable =
          mkEnableOption "River compositor"
          // {default = elem "river" cfg.managers;};
      };

      wayfire = {
        enable =
          mkEnableOption "Wayfire compositor"
          // {default = elem "wayfire" cfg.managers;};
      };

      labwc = {
        enable =
          mkEnableOption "Labwc compositor"
          // {default = elem "labwc" cfg.managers;};
      };

      mango = {
        enable =
          mkEnableOption "Mango compositor"
          // {default = elem "mango" cfg.managers;};
      };

      qtile = {
        enable =
          mkEnableOption "Qtile window manager"
          // {default = elem "qtile" cfg.managers;};
      };

      xmonad = {
        enable =
          mkEnableOption "XMonad window manager"
          // {default = elem "xmonad" cfg.managers;};
      };

      awesome = {
        enable =
          mkEnableOption "Awesome window manager"
          // {default = elem "awesome" cfg.managers;};
      };

      i3 = {
        enable =
          mkEnableOption "i3 window manager"
          // {default = elem "i3" cfg.managers;};
      };

      x11 =
        mkEnableOption "X11 session support"
        // {
          default =
            cfg.qtile.enable
            || cfg.xmonad.enable
            || cfg.awesome.enable
            || cfg.i3.enable
            || elem "cinnamon" cfg.desktops
            || elem "xfce" cfg.desktops;
        };

      wayland =
        mkEnableOption "Wayland protocol/session support"
        // {
          default =
            cfg.hyprland.enable
            || cfg.niri.enable
            || cfg.sway.enable
            || cfg.river.enable
            || cfg.wayfire.enable
            || cfg.labwc.enable
            || cfg.mango.enable
            || elem "gnome" cfg.desktops
            || elem "plasma" cfg.desktops;
        };
    };

    core = preset: cfg:
      opts.base preset cfg;

    home = preset: cfg: let
      base = opts.base preset cfg;
    in
      base
      // {
        hyprland =
          base.hyprland
          // {
            configType = mkOption {
              type = enum ["hyprlang" "lua"];
              default = "hyprlang";
              description = "Home Manager Hyprland configuration format.";
            };
          };
      };
  };

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};
in {
  core = {
    config,
    pkgs,
    ...
  }: let
    inherit ((args config "core")) cfg opt;
  in {
    options = opt (opts.core spec.core cfg);

    config = {
      services = {
        xserver = mkIf cfg.x11 {
          enable = true;

          desktopManager = {
            xterm.enable = false;
            cinnamon.enable = elem "cinnamon" cfg.desktops;
            xfce.enable = elem "xfce" cfg.desktops;
          };

          windowManager = {
            awesome.enable = cfg.awesome.enable;
            i3.enable = cfg.i3.enable;
            qtile.enable = cfg.qtile.enable;
            xmonad.enable = cfg.xmonad.enable;
          };
        };

        desktopManager = mkIf cfg.wayland {
          gnome.enable = elem "gnome" cfg.desktops;
          plasma6.enable = elem "plasma" cfg.desktops;
        };
      };

      programs = {
        hyprland = {
          inherit (cfg.hyprland) enable withUWSM;
        };

        niri = {
          inherit (cfg.niri) enable;
        };

        sway = {
          enable = cfg.sway.enable;
        };

        uwsm = {
          enable = cfg.wayland;

          waylandCompositors = {
            hyprland = mkIf cfg.hyprland.enable {
              prettyName = "Hyprland";
              comment = "Hyprland compositor managed by UWSM";
              binPath = "/run/current-system/sw/bin/Hyprland";
            };

            niri = mkIf cfg.niri.enable {
              prettyName = "Niri";
              comment = "Niri compositor managed by UWSM";
              binPath = "/run/current-system/sw/bin/niri-session";
            };

            sway = mkIf cfg.sway.enable {
              prettyName = "Sway";
              comment = "Sway compositor managed by UWSM";
              binPath = "/run/current-system/sw/bin/sway";
            };
          };
        };
      };

      environment = {
        sessionVariables = mkIf cfg.wayland {
          NIXOS_OZONE_WL = "1";
        };

        systemPackages = with pkgs;
          optionals cfg.wayland [
            cage
            libsecret
            wayland-utils
            wl-clipboard-rs
          ]
          ++ optionals cfg.niri.enable [
            xwayland-satellite-unstable
          ];
      };
    };
  };

  home = {
    config,
    user ? {},
    ...
  }: let
    inherit ((args config "home")) cfg opt;
  in {
    options = opt (opts.home (spec.home user) cfg);

    config = {
      wayland.windowManager.hyprland = {
        inherit (cfg.hyprland) enable configType;
      };

      programs.niri = {
        inherit (cfg.niri) enable;
      };
    };
  };
}
