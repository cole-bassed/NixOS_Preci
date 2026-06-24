{
  lix,
  top,
  dom,
  mod,
  leaf,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs;

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};
in {
  core = {config, ...}: let
    inherit ((args config "core")) cfg;
  in {
    config = {
      programs = {
        hyprland = mkIf cfg.${leaf}.enable {
          inherit (cfg.${leaf}) enable withUWSM;
        };

        uwsm.waylandCompositors.${leaf} = mkIf cfg.${leaf}.enable {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };
  };

  home = {config, ...}: let
    inherit ((args config "home")) cfg;
  in {
    config = {
      wayland.windowManager.hyprland = mkIf cfg.hyprland.enable {
        inherit (cfg.hyprland) enable configType;
      };
    };
  };
}
