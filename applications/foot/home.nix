{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  dom = "applications";
  mod = "foot";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Foot Home Manager configuration";
  };

  config = mkIf cfg.enable {
    programs = {
      foot = {
        enable = true;
      };
    };
  };
}
