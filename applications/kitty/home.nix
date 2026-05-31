{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  dom = "applications";
  mod = "kitty";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Kitty Home Manager configuration";
  };

  config = mkIf cfg.enable {
    programs = {
      kitty = {
        enable = true;
      };
    };
  };
}
