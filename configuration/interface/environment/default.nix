{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.api) getNormalUsers;
  inherit (lix.attrsets) asAttrs namesOf valuesOf;
  inherit (lix.lists) elem maps optionals;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption mkOption;
  inherit (lix.types) enum listOf;

  setOf = list: namesOf (asAttrs list);

  global = {
    host = host.interface.environment or {};

    users =
      maps
      (user: [((user.interface or {}).environment or {})])
      (valuesOf (getNormalUsers host));

    core = {
      managers = setOf (
        (global.host.managers or [])
        ++ maps (user: user.managers or []) global.users
      );
      desktops = setOf (
        (global.host.desktops or [])
        ++ maps (user: user.desktops or []) global.users
      );
    };

    home = user: let
      local = (user.interface or {}).environment or {};
    in {
      managers = setOf (
        (local.managers or []) ++ (global.host.managers or [])
      );
      desktops = setOf (
        (local.desktops or []) ++ (global.host.desktops or [])
      );
    };
  };

  mkOptions = env: cfg: {
    managers = mkOption {
      type = listOf (enum ["hyprland" "niri"]);
      default = env.managers;
      description = "Enabled standalone Wayland compositors/window managers.";
    };

    desktops = mkOption {
      type = listOf (enum ["plasma" "gnome" "xfce" "cinnamon"]);
      default = env.desktops;
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

    wayland =
      mkEnableOption "Wayland protocol/session support"
      // {default = cfg.hyprland.enable || cfg.niri.enable;};
  };

  mkArgs = config: scope: mkModuleArgs {inherit config top dom mod scope;};
in {
  core = {
    config,
    pkgs,
    ...
  }: let
    inherit ((mkArgs config "core")) cfg opt;
  in {
    options = opt (mkOptions global.core cfg);
    config = {
      programs = {
        hyprland = {inherit (cfg.hyprland) enable withUWSM;};
        niri = {inherit (cfg.niri) enable;};
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
          };
        };
      };

      environment = mkIf cfg.wayland {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };
        systemPackages = with pkgs;
          [
            cage
            libsecret
            wayland-utils
            wl-clipboard-rs
          ]
          ++ optionals
          cfg.niri.enable
          [xwayland-satellite-unstable];
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
    options = opt (mkOptions (global.home user) cfg);
    config = {
      wayland.windowManager.hyprland = {inherit (cfg.hyprland) enable;};
      programs.niri = {inherit (cfg.niri) enable;};
    };
  };
}
