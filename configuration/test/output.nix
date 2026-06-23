{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.displays) isRequired mkHyprland mkNiri;
  inherit (lix.options) mkModuleArgs mkOption mkEnableOption;
  inherit (lix.types) attrsOf asFloat nullOr int str submodule;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt mkEnableMod;
    inherit (cfg) enable;

    #? Pull compositor toggles from the interface module's resolved config.
    windowManagers = cfg.interface.windowManagers or {};

    #? Pull displays from this module's own resolved config.
    displays = cfg.displays or {};
  in {
    options = opt {
      compositors = {
        hyprland = {
          enable =
            mkEnableOption "Monitor configuration for hyprland"
            // {default = host.interface.windowManager or null == "hyprland";};
        };
        niri = {
          enable =
            mkEnableOption "Monitor configuration for niri"
            // {default = host.interface.windowManager or null == "niri";};
        };
      };

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
              type = nullOr asFloat;
              default = null;
              description = "Refresh rate in Hz.";
            };
            scale = mkOption {
              type = asFloat;
              default = 1.0;
              description = "Display scale factor.";
            };
            position = mkOption {
              type = nullOr str;
              default = null;
              description = "Position in the virtual layout, format \"XxY\".";
            };
            size = mkOption {
              type = nullOr asFloat;
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
      then {}
      else
        mkIf isRequired {
          wayland.windowManager.hyprland.settings = mkIf (cfg.windowManagers.hyprland.enable) {
            monitor = mkHyprland displays;
          };

          programs.niri.settings.outputs = mkIf (cfg.windowManagers.niri.enable) (mkNiri displays);
        }
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
