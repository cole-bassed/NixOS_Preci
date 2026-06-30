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

  mkArgs = config: scope:
    mkModuleArgs {inherit config top path scope;};
in {
  core = {config, ...}: let
    inherit ((mkArgs config "core")) cfg opt;
    managers = config.${top}.interface.backend.managers;
  in {
    options = opt {
      enable =
        mkEnableOption "Hyprland compositor"
        // {default = elem "hyprland" managers;};

      withUWSM =
        mkEnableOption "launching Hyprland through UWSM"
        // {default = cfg.enable;};
    };

    config = {
      programs = {
        hyprland = {inherit (cfg) enable withUWSM;};
        uwsm.waylandCompositors = mkIf cfg.enable {
          hyprland = {
            prettyName = "Hyprland";
            comment = "Hyprland compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/Hyprland";
          };
        };
      };
    };
  };

  home = {config, ...}: let
    inherit ((mkArgs config "home")) cfg opt;
  in {
    options = opt {
      enable =
        mkEnableOption "Hyprland compositor"
        // {default = config.${top}.interface.backend.managers |> elem "hyprland";};

      configType = mkOption {
        type = enum ["hyprlang" "lua"];
        default = "hyprlang";
        description = "Home Manager Hyprland configuration format.";
      };
    };

    config = mkIf cfg.enable {
      wayland.windowManager.hyprland = {
        inherit (cfg) enable configType;
      };
    };
  };
}
