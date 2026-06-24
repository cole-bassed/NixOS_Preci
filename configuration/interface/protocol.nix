#TODO: Add more protocol defining parts, like clipboard and photo viewer for x11 vs Wayland and others
{
  lix,
  top,
  dom,
  mod,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.lists) any elem optionals;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption;

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  hasAny = values: names:
    any (name: elem name values) names;

  per = {
    x11 = env:
      hasAny env.managers [
        "awesome"
        "i3"
        "qtile"
        "xmonad"
      ]
      || hasAny env.desktops [
        "cinnamon"
        "xfce"
      ];

    wayland = env:
      hasAny env.managers [
        "hyprland"
        "labwc"
        "mango"
        "niri"
        "river"
        "sway"
        "wayfire"
      ]
      || hasAny env.desktops [
        "gnome"
        "plasma"
      ];
  };

  opts = {
    core = env: {
      x11 =
        mkEnableOption "X11 protocol/session support"
        // {default = per.x11 env;};

      wayland =
        mkEnableOption "Wayland protocol/session support"
        // {default = per.wayland env;};
    };

    home = env: opts.core env;
  };

  mk = scope: {
    config,
    pkgs ? null,
    ...
  }: let
    inherit ((args config scope)) cfg opt;
    env = config.${top}.${dom}.environment;
  in {
    options = opt (opts.${scope} env);
    config = optionalAttrs (scope == "core") {
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
          ++ optionals environment.niri.enable [
            xwayland-satellite-unstable
          ];
      };
    };
  };
in {
  core = mk "core";
  home = mk "home";
}
