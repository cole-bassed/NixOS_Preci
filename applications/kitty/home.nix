{
  config,
  lib,
  top,
  ...
}: let
  dom = "applications";
  mod = "kitty";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = lib.mkEnableOption "Kitty Home Manager configuration";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      kitty = {
        enable = true;
      };
    };
  };
}
