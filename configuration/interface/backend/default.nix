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
  inherit (lix.lists) elem concatMap;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) enum listOf;

  setOf = list: namesOf (asAttrs list);

  getUI = base:
    (base.interface or {}).backend or {};

  collect = field: specs:
    setOf (concatMap (spec: spec.${field} or []) specs);

  merge = specs: {
    managers = collect "managers" specs;
    desktops = collect "desktops" specs;
  };

  spec = let
    host' = getUI host;
    users = map getUI (valuesOf (getInteractiveUsers host));

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
      managers = with managers; x11 ++ wayland;
      desktops = with desktops; x11 ++ wayland;
      x11 = managers.x11 ++ desktops.x11;
      wayland = managers.wayland ++ desktops.wayland;
    };

    host = host';
    inherit users;

    core = merge ([host'] ++ users);

    home = user: let
      user' = getUI user;
    in
      merge [host' user'];
  };

  opts = {
    base = preset: cfg: {
      managers = mkOption {
        type = listOf (enum spec.all.managers);
        default = preset.managers;
        description = "Enabled standalone compositors/window managers for the backend layer.";
      };

      desktops = mkOption {
        type = listOf (enum spec.all.desktops);
        default = preset.desktops;
        description = "Enabled full desktop environments for the backend layer.";
      };

      hyprland = {
        enable =
          mkEnableOption "Hyprland compositor"
          // {default = elem "hyprland" cfg.managers;};

        withUWSM =
          mkEnableOption "launching Hyprland through UWSM"
          // {default = cfg.hyprland.enable;};
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

  mkArgs = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};
in {
  core = {config, ...}: let
    inherit ((mkArgs config "core")) cfg opt;
    protocol = config.${top}.interface.protocol;
  in {
    options = opt (opts.core spec.core cfg);

    config = {
      home-manager.sharedModules = mkIf cfg.niri.enable [
        {
          options.programs.niri.enable = mkEnableOption "Niri compositor";
        }
      ];

      services = {
        xserver = mkIf protocol.x11 {
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

        desktopManager = mkIf protocol.wayland {
          gnome.enable = elem "gnome" cfg.desktops;
          plasma6.enable = elem "plasma" cfg.desktops;
        };
      };

      programs = {
        hyprland.enable = cfg.hyprland.enable;
        niri.enable = cfg.niri.enable;
        sway.enable = cfg.sway.enable;
      };
    };
  };

  home = {
    config,
    user ? {},
    ...
  }: let
    inherit ((mkArgs config "home")) cfg opt;
  in {
    options = opt (opts.home (spec.home user) cfg);
    config = {
      programs.niri.enable = cfg.niri.enable;
    };
  };
}
