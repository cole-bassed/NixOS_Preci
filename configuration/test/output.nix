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
  inherit (lix.types) attrsOf bool either nullOr int float str submodule;

  #? Schema S8: devices.display entries.

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      displays = let
        entry = submodule {
          options = {
            enable = mkEnableMod.true;
            brand = mkOption {
              type = nullOr str;
              default = null;
              description = "Display/panel manufacturer.";
            };
            resolution = mkOption {
              type = nullOr str;
              default = null;
              description = "Native resolution, format \"WxH\".";
            };
            refreshRate = mkOption {
              type = nullOr float;
              default = null;
              description = "Refresh rate in Hz.";
            };
            scale = mkOption {
              type = float;
              default = 1.0;
              description = "Display scale factor.";
            };
            position = mkOption {
              type = nullOr str;
              default = null;
              description = "Position in the virtual layout, format \"XxY\".";
            };
            size = mkOption {
              type = nullOr float;
              default = null;
              description = "Physical panel size, diagonal inches.";
            };
            priority = mkOption {
              type = int;
              default = 0;
              description = "Display ordering priority; 0 is primary.";
            };
          };
        };
      in
        mkOption {
          type = attrsOf entry;
          default = host.devices.display or {};
          description = "Output/display layout, keyed by connector name.";
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
