{
  lix,
  top,
  dom,
  mod,
  registry,
  ...
}: let
  inherit (lix.attrsets) attrNames optionalAttrs;
  inherit (lix.lists) any elem isList optionals;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption;

  args = config: scope: mkModuleArgs {inherit config top dom mod scope;};

  # Get backend names from config
  backendNames = config: let
    raw = config.${top}.interface.backends or [];
  in
    if isList raw
    then raw
    else attrNames raw;

  # Derive protocol support from registry
  per = protocol: names:
    any (
      name: let
        env = registry.environments.${name} or {};
      in
        env.protocol or null == protocol
    )
    names;

  opts = names: {
    x11 =
      mkEnableOption "X11 protocol/session support"
      // {
        default = per "x11" names;
      };
    wayland =
      mkEnableOption "Wayland protocol/session support"
      // {
        default = per "wayland" names;
      };
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
