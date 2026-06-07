{
  lix,
  top,
  host,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.attrsets) removeNulls orEmpty;
  inherit
    (lix.options)
    mkModuleArgs
    mkLatitudeOption
    mkLongitudeOption
    mkGeoProviderOption
    mkTimezoneOption
    mkLocaleOption
    mkLocalTimeOption
    ;

  mk = scope: {config, ...}: let
    _ = mkModuleArgs {inherit config top dom mod scope;};
    inherit (_) cfg opt mkEnableMod;
    inherit (cfg) enable;
  in {
    options = opt {
      enable = mkEnableMod.true;
      latitude = mkLatitudeOption {inherit host;};
      longitude = mkLongitudeOption {inherit host;};
      provider = mkGeoProviderOption {inherit host;};
      timezone = mkTimezoneOption {inherit host;};
      locale = mkLocaleOption {inherit host;};
      useLocalTime = mkLocalTimeOption {inherit host;};
    };

    config = mkIf enable (
      if scope == "core"
      then {
        location = removeNulls {
          inherit (cfg) latitude longitude provider;
        };
        time =
          {hardwareClockInLocalTime = cfg.useLocalTime;}
          // removeNulls {timeZone = cfg.timezone;};
        i18n.defaultLocale = cfg.locale;
      }
      else {home.language.base = cfg.locale;}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
