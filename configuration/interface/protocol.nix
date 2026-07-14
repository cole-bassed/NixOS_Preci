{
  lix,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) attrByPath optionalAttrs;
  inherit (lix.lists) any optionals;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkEnableOption;

  per = protocol: names: backends:
    any (name: attrByPath [name "protocol"] null backends == protocol) names;

  wantsXwaylandSatellite = names: backends:
    any (name: attrByPath [name "needsXwaylandSatellite"] false backends) names;

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
  in {
    options = opt {
      x11 = mkEnableOption "X11 support" // {default = per "x11" data.names data.values;};
      wayland = mkEnableOption "Wayland support" // {default = per "wayland" data.names data.values;};
    };

    config = optionalAttrs (scope == "core") {
      services.xserver.enable = cfg.x11;
      programs.uwsm.enable = cfg.wayland;
      environment = {
        sessionVariables = mkIf cfg.wayland {NIXOS_OZONE_WL = "1";};
        systemPackages = with pkgs;
          optionals cfg.wayland [cage libsecret wayland-utils wl-clipboard-rs]
          ++ optionals (wantsXwaylandSatellite data.names data.values) [xwayland-satellite];
      };
    };
  };
in {
  core = mk "core";
  home = mk "home";
}
