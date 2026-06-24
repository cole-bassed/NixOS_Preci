{
  lix,
  top,
  dom,
  mod,
  ...
}: let
  inherit (lix.lists) elem optionals;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption;

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  hasAny = values: names:
    builtins.any (name: elem name values) names;

  opts = cfg: session: {
    x11 =
      mkEnableOption "X11 protocol/session support"
      // {
        default =
          cfg.x11.enable
          || hasAny session.managers [
            "awesome"
            "i3"
            "qtile"
            "xmonad"
          ]
          || hasAny session.desktops [
            "cinnamon"
            "xfce"
          ];
      };

    wayland =
      mkEnableOption "Wayland protocol/session support"
      // {
        default =
          cfg.wayland.enable
          || hasAny session.managers [
            "hyprland"
            "labwc"
            "mango"
            "niri"
            "river"
            "sway"
            "wayfire"
          ]
          || hasAny session.desktops [
            "gnome"
            "plasma"
          ];
      };
  };
in {
  core = {
    config,
    pkgs,
    ...
  }: let
    inherit ((args config "core")) cfg opt;
    session = config.${top}.${dom}.session;
  in {
    options = opt (opts cfg session);

    config = {
      services.xserver.enable = cfg.x11.enable;
      programs.uwsm.enable = cfg.wayland.enable;

      environment = {
        sessionVariables = mkIf cfg.wayland.enable {
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
          QT_QPA_PLATFORM = "wayland;xcb";
          SDL_VIDEODRIVER = "wayland,x11";
        };

        systemPackages = with pkgs;
          optionals cfg.wayland.enable [
            cage
            libsecret
            wayland-utils
            wl-clipboard-rs
          ]
          ++ optionals session.niri.enable [
            xwayland-satellite-unstable
          ];
      };
    };
  };

  home = {config, ...}: let
    inherit ((args config "home")) cfg opt;
    session = config.${top}.${dom}.session;
  in {
    options = opt (opts cfg session);

    config = {};
  };
}
