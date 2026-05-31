{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool package;

  dom = "applications";
  mod = "vicinae";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Vicinae launcher profile";

    package = mkOption {
      type = package;
      default = pkgs.vicinae;
      description = "Vicinae package to install for the desktop launcher application profile.";
    };

    fallbackPackage = mkOption {
      type = package;
      default = pkgs.fuzzel;
      description = "Fallback launcher package used when Vicinae cannot open.";
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

    home.packages = [cfg.fallbackPackage];
  };
}
