{
  lix,
  top,
  lib,
  pkgs,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkDefault mkIf;
  inherit (lix) mkModuleArgs mkEnable;
in {
  core = [];

  home = {config, ...}: let
    scope = "home";
    inherit (mkModuleArgs {inherit config top dom mod scope;}) cfg opt mkEnableMod;

    # Shared launch command used by both compositors
    launch = "${cfg.package}/bin/vicinae";
  in {
    options = opt {
      enable = mkEnableMod.false;

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vicinae;
        description = "Vicinae package to install for the desktop launcher application profile.";
      };

      fallbackPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.fuzzel;
        description = "Fallback launcher package used when Vicinae cannot open.";
      };

      systemd.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to start the Vicinae daemon through Home Manager's user service.";
      };

      onHyprland = (mkEnable {name = "Vicinae on Hyprland";}).true;
      onNiri = (mkEnable {name = "Vicinae on Niri";}).true;
    };

    config = mkIf cfg.enable {
      programs.vicinae = {
        enable = mkDefault true;
        package = mkDefault cfg.package;
        systemd.enable = mkDefault cfg.systemd.enable;
      };

      home.packages = [cfg.fallbackPackage];

      wayland.windowManager.hyprland.settings.bind = mkIf cfg.onHyprland [
        "SUPER, Z, exec, ${launch}"
      ];

      programs.niri.settings.binds = mkIf cfg.onNiri {
        "Mod+Z".action.spawn = [launch];
      };
    };
  };
}
