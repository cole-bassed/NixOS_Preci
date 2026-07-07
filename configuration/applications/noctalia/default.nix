{
  lix,
  top,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkDefault mkForce mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) package str;
  inherit (lix.options) mkModuleArgs;
  inherit (lix) mkEnable;
in {
  core = [];

  home = {config, ...}: let
    scope = "home";
    module = mkModuleArgs {inherit config top dom mod scope;};
    cfg = module.get.config.module;
    opt = module.set.options.module;
  in {
    options = opt {
      enable = module.set.enable {default = false;};
      package = mkOption {
        type = package;
        # default = pkgs.noctalia-shell;
        description = "Noctalia shell package used for the common Wayland panel/bar layer.";
      };
      command = mkOption {
        type = str;
        default = "noctalia-shell";
        description = "Command used by compositor-specific startup hooks.";
      };
      onHyprland = (mkEnable {name = "Noctalia on Hyprland";}).true;
      onNiri = (mkEnable {name = "Noctalia on Niri";}).true;
    };

    config = mkIf cfg.enable {
      programs.noctalia = {
        enable = mkDefault true;
        package = mkForce cfg.package;
        # The upstream module warns that systemd integration is deprecated, so
        # keep startup explicit in each compositor for now.
        systemd.enable = mkDefault false;
      };

      programs.niri.settings.spawn-at-startup = mkIf cfg.onNiri [{argv = [cfg.command];}];
      wayland.windowManager.hyprland.settings.exec-once = mkIf cfg.onHyprland [cfg.command];
    };
  };
}
