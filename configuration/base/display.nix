{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) attrsOf either nullOr int float str bool;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      monitors = mkOption {
        type = attrsOf (attrsOf (nullOr (either str int float bool)));
        default = host.displays or {};
        description = "Display/monitor configurations keyed by output name.";
      };
    };

    config = mkIf enable (
      if scope == "core"
      then {
        # Display configuration is typically handled by the compositor/wm module
        # This module provides the structured data for other modules to consume
        # e.g., Hyprland, niri, or kanshi can read config.dots.displays
      }
      else {}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
