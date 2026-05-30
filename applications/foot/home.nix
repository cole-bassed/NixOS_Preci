{
  config,
  lib,
  top,
  ...
}: let
  dom = "applications";
  mod = "foot";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = lib.mkEnableOption "Foot Home Manager configuration";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      foot = {
        enable = true;
      };
    };
  };
}
