{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkEnableOption;

  dom = "applications";
  mod = "starship";

  cfg = config.${top}.${dom}.${mod};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption "Starship prompt profile";
  };

  config = mkIf cfg.enable {
    programs = {
      starship = {
        enable = mkDefault true;
      };
    };
  };
}
