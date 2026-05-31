{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) bool;

  dom = "applications";
  mod = "alacritty";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkOption {
      type = bool;
      default = true;
      description = "Whether to install Alacritty system-wide.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [
        pkgs.alacritty
      ];
    };
  };
}
