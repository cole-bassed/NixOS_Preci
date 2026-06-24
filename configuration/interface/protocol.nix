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

  wantsX11 = session:
    hasAny session.managers [
      "awesome"
      "i3"
      "qtile"
      "xmonad"
    ]
    || hasAny session.desktops [
      "cinnamon"
      "xfce"
    ];

  wantsWayland = session:
    hasAny session.managers [
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

  opts = session: {
    x11 =
      mkEnableOption "X11 protocol/session support"
      // {
        default = wantsX11 session;
      };

    wayland =
      mkEnableOption "Wayland protocol/session support"
      // {
        default = wantsWayland session;
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
    options = opt (opts session);

    config = {
      services.xserver.enable = cfg.x11;

      programs.uwsm.enable = cfg.wayland;

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
          ++ optionals session.niri.enable [
            xwayland-satellite-unstable
          ];
      };
    };
  };

  home = {config, ...}: let
    inherit ((args config "home")) opt;
    session = config.${top}.${dom}.session;
  in {
    options = opt (opts session);
    config = {};
  };
}
