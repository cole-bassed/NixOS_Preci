{
  config,
  inputs,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib.modules) mkDefault mkForce mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool package str;

  dom = "applications";
  mod = "noctalia";

  cfg = config.${top}.${dom}.${mod};
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Noctalia common panel/bar layer";

    package = mkOption {
      type = package;
      default = pkgs.noctalia-shell;
      description = "Noctalia shell package used for the common Wayland panel/bar layer.";
    };

    command = mkOption {
      type = str;
      default = "noctalia-shell";
      description = "Command used by compositor-specific startup hooks.";
    };

    hyprland.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to start Noctalia from Hyprland exec-once.";
    };

    niri.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to start Noctalia from Niri spawn-at-startup.";
    };
  };

  config = mkIf cfg.enable {
    programs.noctalia-shell = {
      enable = mkDefault true;
      package = mkForce cfg.package;
      # The upstream module warns that systemd integration is deprecated, so
      # keep startup explicit in each compositor for now.
      systemd.enable = mkDefault false;
    };

    wayland.windowManager.hyprland.settings.exec-once = mkIf cfg.hyprland.enable [cfg.command];

    programs.niri.settings.spawn-at-startup = mkIf cfg.niri.enable [
      {argv = [cfg.command];}
    ];
  };
}
