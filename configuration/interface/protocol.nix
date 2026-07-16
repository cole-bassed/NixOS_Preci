{
  lix,
  top,
  host,
  api,
  path,
  ...
}: let
  inherit (lix.attrsets) attrByPath optionalAttrs;
  inherit (lix.lists) any optionals;
  inherit (lix.modules) mkIf mkModuleArgs;
  inherit (lix.options) mkEnableOption;
  inherit (api) interfaceBackends interfaceRegistry;

  names = interfaceBackends host;
  values = interfaceRegistry;

  per = protocol: any (name: attrByPath [name "protocol"] null values == protocol) names;
  wantsXwaylandSatellite = any (name: attrByPath [name "needsXwaylandSatellite"] false values) names;

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    inherit (mkModuleArgs {inherit config top scope path;}) get set;
    inherit (get) cfg;
    inherit (set) opt;
  in {
    options = opt {
      x11 = mkEnableOption "X11 support" // {default = per "x11";};
      wayland = mkEnableOption "Wayland support" // {default = per "wayland";};
    };

    config = optionalAttrs (scope == "core") {
      services.xserver.enable = cfg.x11;
      programs.uwsm.enable = cfg.wayland;
      environment = {
        sessionVariables = mkIf cfg.wayland {NIXOS_OZONE_WL = "1";};
        systemPackages = with pkgs;
          optionals cfg.wayland [cage libsecret wayland-utils wl-clipboard-rs]
          ++ optionals wantsXwaylandSatellite [xwayland-satellite];
      };
    };
  };
in {
  core = mk "core";
  home = mk "home";
}
