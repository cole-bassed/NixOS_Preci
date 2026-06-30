{
  lix,
  top,
  path,
  ...
}: let
  inherit (lix.lists) elem;
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkEnableOption mkModuleArgs mkOption;
  inherit (lix.types) enum;

  # Helper to resolve common environment defaults
  isManaged = config: elem "hyprland" config.${top}.interface.backend.managers;

  mkArgs = config: scope: mkModuleArgs {inherit config top path scope;};
in {
  core = {config, ...}: let
    inherit ((mkArgs config "core")) cfg opt;
  in {
    options = opt {
      enable = mkEnableOption "Hyprland compositor" // {default = isManaged config;};
      withUWSM = mkEnableOption "launching Hyprland through UWSM" // {default = cfg.enable;};
    };

    config = mkIf cfg.enable {
      programs = {
        hyprland = {inherit (cfg) enable withUWSM;};
        uwsm.waylandCompositors.hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };
  };

  home = {config, ...}: let
    inherit ((mkArgs config "home")) cfg opt;
  in {
    options = opt {
      enable = mkEnableOption "Hyprland compositor" // {default = isManaged config;};
      configType = mkOption {
        type = enum ["hyprlang" "lua"];
        default = "hyprlang";
        description = "Home Manager Hyprland configuration format.";
      };
    };

    config = mkIf cfg.enable {
      wayland.windowManager.hyprland = {inherit (cfg) enable configType;};
    };
  };
}
