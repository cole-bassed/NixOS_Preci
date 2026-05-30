{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf;

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
