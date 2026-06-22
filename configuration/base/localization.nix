{
  lix,
  top,
  host,
  ...
}: let
  inherit (lix.attrsets) removeEmpty;
  inherit (lix.options) mkOption;
  inherit (lix.types) attrsOf anything;
  mod = "localization";
  src = host.${mod} or {};

  data = {
    latitude = src.latitude or null;
    longitude = src.longitude or null;
    provider = src.locator or src.provider or "manual";
    timezone = src.timezone or null;
    locale = src.locale or "en_US.UTF-8";
    useLocalTime = src.useLocalTime or true;
  };

  mk = scope: {...}: {
    options.${top}.${mod} = mkOption {
      type = attrsOf anything;
      default = {};
      description = "Resolved host localization data: geographic coordinates, location provider, timezone, locale, and clock mode.";
    };

    config =
      {${top}.localization = data;}
      // (
        if scope == "core"
        then {
          location = removeEmpty {
            inherit (data) latitude longitude provider;
          };
          time =
            {hardwareClockInLocalTime = data.useLocalTime;}
            // removeEmpty {timeZone = data.timezone;};
          i18n.defaultLocale = data.locale;
        }
        else {home.language.base = data.locale;}
      );
  };
in {
  core = mk "core";
  home = mk "home";
}
