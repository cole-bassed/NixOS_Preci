{
  config,
  lix,
  top,
  host,
  # dom,
  # mod,
  ...
}: let
  dom = "modules";
  mod = "localization";
  cfg = config.${top}.${dom}.${mod};

  # inherit (lix.modules) mkIf;
  inherit (lix.attrsets) removeEmpty;
  inherit
    (lix.options)
    # mkModuleArgs
    # mkEnableOption
    mkLatitudeOption
    mkLongitudeOption
    mkGeoProviderOption
    mkTimezoneOption
    mkLocaleOption
    mkLocalTimeOption
    ;
  core = {
    options.${top}.${dom}.${mod} = {
      # enable = mkEnableOption mod // {default = true;};
      latitude = mkLatitudeOption {inherit host;};
      longitude = mkLongitudeOption {inherit host;};
      provider = mkGeoProviderOption {inherit host;};
      timezone = mkTimezoneOption {inherit host;};
      locale = mkLocaleOption {inherit host;};
      useLocalTime = mkLocalTimeOption {inherit host;};
    };
    config = {
      location = removeEmpty {
        inherit (cfg) latitude longitude provider;
      };
      time =
        {hardwareClockInLocalTime = cfg.useLocalTime;}
        // removeEmpty {timeZone = cfg.timezone;};
      i18n.defaultLocale = cfg.locale;
    };
  };
  # mk = scope: {config, ...}: let
  #   _ = mkModuleArgs {inherit config top dom mod scope;};
  #   inherit (_) cfg opt mkEnableMod;
  #   inherit (cfg) enable;
  # in {
  #   options = opt {
  #     enable = mkEnableMod.true;
  #     latitude = mkLatitudeOption {inherit host;};
  #     longitude = mkLongitudeOption {inherit host;};
  #     provider = mkGeoProviderOption {inherit host;};
  #     timezone = mkTimezoneOption {inherit host;};
  #     locale = mkLocaleOption {inherit host;};
  #     useLocalTime = mkLocalTimeOption {inherit host;};
  #   };
  #   config = mkIf enable (
  #     if scope == "core"
  #     then {
  #       location = removeNulls {
  #         inherit (cfg) latitude longitude provider;
  #       };
  #       time =
  #         {hardwareClockInLocalTime = cfg.useLocalTime;}
  #         // removeNulls {timeZone = cfg.timezone;};
  #       i18n.defaultLocale = cfg.locale;
  #     }
  #     else {home.language.base = cfg.locale;}
  #   );
  # };
  # in {
  #   inherit core;
  #   # core = mk "core";
  #   # home = mk "home";
  # }
in
  core
