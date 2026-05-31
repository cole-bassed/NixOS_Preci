{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  dom = "applications";
  mod = "alacritty";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Alacritty Home Manager configuration";
  };

  config = mkIf cfg.enable {
    programs = {
      alacritty = {
        enable = true;
      };
    };
  };
}
