# {
#   lix,
#   host,
#   ...
# }: let
#   inherit (lix.predicates) isValidGeoCoords;
#   inherit (lix.debug) warnWithContext;
#   location = let
#     isValid = isValidGeoCoords {inherit latitude longitude;};
#     _warn = warnWithContext {
#       name = "localization";
#       assertion = isValid;
#       message = "invalid coordinates (${toString latitude}, ${toString longitude}); falling back to geoclue";
#       context = "evaluating host localization for ${host.name or "unknown"}";
#     };
#     invalid = 999.0;
#     longitude = host.localization.longitude or invalid;
#     latitude = host.localization.latitude  or invalid;
#     provider =
#       if _warn && isValid
#       then host.localization.locator or "manual"
#       else "geoclue";
#   in {inherit latitude longitude provider;};
# in {inherit location;}
{
  lix,
  top,
  pkgs,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix) mkModuleArgs;

  mk = scope: {config, ...}: let
    _ = mkModuleArgs {inherit config top dom mod scope;};
    inherit (_) cfg opt mkEnableMod;
    package = pkgs.${mod};
    inherit (cfg) enable;
  in {
    options = opt {enable = mkEnableMod.false;};
    config = mkIf enable (
      if scope == "core"
      then {environment.systemPackages = [package];}
      else {programs.${mod} = {inherit enable package;};}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
