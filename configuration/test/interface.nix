{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkEnableOption;

  mk = scope: {config, ...}: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) cfg opt;
    inherit (cfg) enable;
  in {
    options = opt {
      desktopEnvironments = {};
      windowManagers = {
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
    };

    config = mkIf enable (
      if scope == "core"
      then {
        #TODO: enable the desktopEnvironments;
      }
      else {
        #TODO: enable the ;
      }
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
