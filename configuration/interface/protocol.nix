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

  args = config: scope: mkModuleArgs {inherit config top dom mod scope;};

  hasAny = values: names: any (name: elem name values) names;

  backendNames = config: let
    raw = config.${top}.interface.backends or [];
  in
    if builtins.isList raw
    then raw
    else builtins.attrNames raw;

  per = {
    x11 = names: hasAny names ["awesome" "i3" "qtile" "xmonad" "cinnamon" "xfce"];
    wayland = names: hasAny names ["hyprland" "labwc" "mango" "niri" "river" "sway" "wayfire" "gnome" "plasma" "cosmic"];
  };

  opts = env: {
    x11 = mkEnableOption "X11 protocol/session support" // {default = per.x11 env;};
    wayland = mkEnableOption "Wayland protocol/session support" // {default = per.wayland env;};
  };

  mk = scope: {
    config,
    pkgs ? null,
    ...
  }: let
    inherit ((args config scope)) cfg opt;
    names = backendNames config;
  in {
    options = opt (opts names);
    config = optionalAttrs (scope == "core") {
      services.xserver.enable = cfg.x11;
      programs.uwsm.enable = cfg.wayland;
      environment = {
        sessionVariables = mkIf cfg.wayland {NIXOS_OZONE_WL = "1";};
        systemPackages = with pkgs;
          optionals cfg.wayland [cage libsecret wayland-utils wl-clipboard-rs]
          ++ optionals (elem "niri" names) [xwayland-satellite];
      };
    };
  };
in {
  core = mk "core";
  home = mk "home";
}
