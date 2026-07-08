{
  lix,
  top,
  dom,
  mod,
  ...
}: let
  inherit (lix.attrsets) attrByPath attrNames isAttrs optionalAttrs;
  inherit (lix.lists) any isList optionals;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkEnableOption mkModuleArgs;

  args = config: scope: mkModuleArgs {inherit config top dom mod scope;};

  backendAttrs = config: config.${top}.interface.backends or {};

  backendNames = config: let
    raw = backendAttrs config;
  in
    if isList raw
    then raw
    else if isAttrs raw
    then attrNames raw
    else [];

  per = protocol: names: backends:
    any (name: attrByPath [name "protocol"] null backends == protocol) names;

  wantsXwaylandSatellite = names: backends:
    any (name: attrByPath [name "needsXwaylandSatellite"] false backends) names;

  opts = names: backends: {
    x11 =
      mkEnableOption "X11 protocol/session support"
      // {
        default = per "x11" names backends;
      };
    wayland =
      mkEnableOption "Wayland protocol/session support"
      // {
        default = per "wayland" names backends;
      };
  };

  mk = scope: {
    config,
    pkgs ? null,
    ...
  }: let
    mod = args config scope;
    cfg = mod.get.config.module;
    opt = mod.set.options.module;
    names = backendNames config;
    backends = backendAttrs config;
  in {
    options = opt (opts names backends);
    config = optionalAttrs (scope == "core") {
      services.xserver.enable = cfg.x11;
      programs.uwsm.enable = cfg.wayland;
      environment = {
        sessionVariables = mkIf cfg.wayland {NIXOS_OZONE_WL = "1";};
        systemPackages = with pkgs;
          optionals cfg.wayland [cage libsecret wayland-utils wl-clipboard-rs]
          ++ optionals (wantsXwaylandSatellite names backends) [xwayland-satellite];
      };
    };
  };
in {
  core = mk "core";
  home = mk "home";
}
