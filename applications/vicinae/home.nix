{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption;
  inherit (lib.types) bool package str;

  dom = "applications";
  mod = "vicinae";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Vicinae launcher profile";

    package = mkOption {
      type = package;
      default = pkgs.vicinae;
      description = "Vicinae package to install for the shared launcher action.";
    };

    fallbackPackage = mkOption {
      type = package;
      default = pkgs.fuzzel;
      description = "Fallback launcher package used when Vicinae cannot open.";
    };

    command = mkOption {
      type = str;
      default = "vicinae open || fuzzel";
      description = "Compositor-agnostic launcher command consumed by the shared keybind layer.";
    };

    systemd.enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to start the Vicinae daemon through Home Manager's user service.";
    };
  };

  config = mkIf cfg.enable {
    programs.vicinae = {
      enable = mkDefault true;
      package = mkDefault cfg.package;
      systemd.enable = mkDefault cfg.systemd.enable;
    };

    ${top}.${dom}.keybinds.actions.launcher.command = mkDefault cfg.command;

    home.packages = [cfg.fallbackPackage];
  };
}
