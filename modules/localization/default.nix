# {
#   options = {
#     time = {
#       timeZone = lib.mkOption {
#         default = null;
#         type = timezone;
#         example = "America/New_York";
#         description = ''
#           The time zone used when displaying times and dates. See <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones>
#           for a comprehensive list of possible values for this setting.
#           If null, the timezone will default to UTC and can be set imperatively
#           using timedatectl.
#         '';
#       };
#       hardwareClockInLocalTime = lib.mkOption {
#         default = false;
#         type = lib.types.bool;
#         description = "If set, keep the hardware clock in local time instead of UTC.";
#       };
#     };
#     location = {
#       latitude = lib.mkOption {
#         type = lib.types.float;
#         description = ''
#           Your current latitude, between
#           `-90.0` and `90.0`. Must be provided
#           along with longitude.
#         '';
#       };
#       longitude = lib.mkOption {
#         type = lib.types.float;
#         description = ''
#           Your current longitude, between
#           between `-180.0` and `180.0`. Must be
#           provided along with latitude.
#         '';
#       };
#       provider = lib.mkOption {
#         type = lib.types.enum [
#           "manual"
#           "geoclue2"
#         ];
#         default = "manual";
#         description = ''
#           The location provider to use for determining your location. If set to
#           `manual` you must also provide latitude/longitude.
#         '';
#       };
#     };
#   };
#   config = {
#     environment.sessionVariables.TZDIR = "/etc/zoneinfo";
#     services.geoclue2.enable = lib.mkIf (lcfg.provider == "geoclue2") true;
#     # This way services are restarted when tzdata changes.
#     systemd.globalEnvironment.TZDIR = tzdir;
#     systemd.services.systemd-timedated.environment = lib.optionalAttrs (config.time.timeZone != null) {
#       NIXOS_STATIC_TIMEZONE = "1";
#     };
#     environment.etc = {
#       zoneinfo.source = tzdir;
#     }
#     // lib.optionalAttrs (config.time.timeZone != null) {
#       localtime.source = "/etc/zoneinfo/${config.time.timeZone}";
#       localtime.mode = "direct-symlink";
#     };
#   };
# }
{
  lix,
  top,
  pkgs,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs mkFloatOption;
  inherit (lix.predicates) isValidGeoCoords;
  inherit (lix.debug) warnWithContext;

  location = let
    isValid = isValidGeoCoords {inherit latitude longitude;};
    _warn = warnWithContext {
      name = "localization";
      assertion = isValid;
      message = "invalid coordinates (${toString latitude}, ${toString longitude}); falling back to geoclue";
      context = "evaluating host localization for ${host.name or "unknown"}";
    };
    invalid = 999.0;
    longitude = host.localization.longitude or invalid;
    latitude = host.localization.latitude  or invalid;
    provider =
      if _warn && isValid
      then host.localization.locator or "manual"
      else "geoclue";
  in {inherit latitude longitude provider;};

  mk = scope: {config, ...}: let
    _ = mkModuleArgs {inherit config top dom mod scope;};
    inherit (_) cfg opt mkEnableMod;
    package = pkgs.${mod};
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      latitude = mkFloatOption {
        description = ''
          Your current latitude, between
          `-90.0` and `90.0`. Must be provided
          along with longitude.
        '';
        default = location.latitude;
      };
      longitude = mkFloatOption {
        description = ''
          Your current longitude, between
          between `-180.0` and `180.0`. Must be
          provided along with latitude.
        '';
        default = location.longitude;
      };
    };
    config = mkIf enable (
      if scope == "core"
      then {inherit location;}
      else {programs.${mod} = {inherit enable package;};}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
