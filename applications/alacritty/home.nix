{
  config,
  lib,
  top,
  ...
}: let
  dom = "applications";
  mod = "alacritty";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = lib.mkEnableOption "Alacritty Home Manager configuration";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      alacritty = {
        enable = true;
      };
    };
  };
}
