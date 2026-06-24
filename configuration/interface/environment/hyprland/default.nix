{
  lix,
  top,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs;

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  env = config:
    config.${top}.${dom}.environment;
in {
  core = {config, ...}: let
    cfg = env config;
  in {
    config = {
      programs = {
        hyprland = mkIf cfg.hyprland.enable {
          inherit (cfg.hyprland) enable withUWSM;
        };

        uwsm.waylandCompositors.hyprland = mkIf cfg.hyprland.enable {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };
  };

  home = {config, ...}: let
    cfg = env config;
  in {
    config = {
      wayland.windowManager.hyprland = mkIf cfg.hyprland.enable {
        inherit (cfg.hyprland) enable configType;
      };
    };
  };
}
