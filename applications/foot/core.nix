{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  dom = "applications";
  mod = "foot";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install Foot system-wide.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [
        pkgs.foot
      ];
    };
  };
}
