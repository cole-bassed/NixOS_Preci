{
  attrsets,
  lists,
  options,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit
        mkEnable
        mkCfg
        mkOpt
        mkEnableMod
        mkModuleArgs
        mkFloatOption
        mkLatitudeOption
        mkLongitudeOption
        mkGeoProviderOption
        mkTimezoneOption
        mkLocalTimeOption
        mkLocaleOption
        ;
    };
    global = {inherit mkModuleArgs;};
  };

  inherit (attrsets) attrByPath setAttrByPath optionalAttrs;
  inherit (lists) asList hasAny;
  inherit (options) mkOption mkEnableOption;
  inherit (types) nullOr addCheck float str;

  mkEnable = {
    name ? null,
    mod ? null,
    description ? null,
    scope ? "core",
  }: let
    module =
      if name != null && name != ""
      then name
      else if mod != null && mod != ""
      then mod
      else null;

    description' =
      if description != null
      then description
      else if module != null
      then "Whether ${module} should be enabled ${
        if scope == "core"
        then "system-wide"
        else if scope == "home"
        then "for the user"
        else throw "Expected scope to be one of [core home], got ${scope}"
      }"
      else "Whether to enable this module";
  in {
    false = mkEnableOption description';
    true = mkEnableOption description' // {default = true;};
  };

  mkCfg = {
    config,
    path,
  }:
    attrByPath (asList path) {} config;

  mkOpt = {
    options,
    path,
  }:
    setAttrByPath (asList path) options;

  mkEnableMod = {
    mod,
    scope,
  }:
    mkEnable {inherit mod scope;};

  mkModuleArgs = {
    config,
    top,
    dom,
    mod,
    scope ? "core",
  }: let
    path = [top dom mod];
  in {
    cfg = mkCfg {inherit config path;};
    opt = options: mkOpt {inherit options path;};
    mkEnableMod = mkEnableMod {inherit mod scope;};
  };

  mkFloatOption = {
    description,
    min ? null,
    max ? null,
    default ? null,
  }: let
    check = value:
      (
        if min != null
        then value >= min
        else true
      )
      && (
        if max != null
        then value <= max
        else true
      );
  in
    mkOption ({
        type = nullOr (addCheck float check);
        inherit description;
      }
      // optionalAttrs (default != null) {inherit default;});

  mkLatitudeOption = {
    host,
    default ? null,
  }:
    mkFloatOption {
      description = "Latitude coordinate, between -90.0 and 90.0";
      min = -90.0;
      max = 90.0;
      default = host.localization.latitude or default;
    };

  mkLongitudeOption = {
    host,
    default ? null,
  }:
    mkFloatOption {
      description = "Longitude coordinate, between -180.0 and 180.0";
      min = -180.0;
      max = 180.0;
      default = host.localization.longitude or default;
    };

  mkGeoProviderOption = {
    host,
    default ? "manual",
  }: let
    loc = host.localization or {};
    provider = loc.provider or null;
    latitude = loc.latitude or null;
    longitude = loc.longitude or null;
  in
    mkOption {
      type = types.enum ["manual" "geoclue2"];
      description = "Location provider. If 'manual', valid latitude and longitude must be provided.";
      default =
        if provider != null
        then provider
        else if latitude != null && longitude != null
        then default
        else "geoclue2";
    };

  mkTimezoneOption = {
    host,
    default ? null,
  }:
    mkOption ({
        type = nullOr str;
        description = "The system or user timezone.";
      }
      // optionalAttrs (host.localization.timezone or default != null) {
        default = host.localization.timezone or default;
      });

  mkLocalTimeOption = {host}: let
    useLocalTime =
      hasAny
      ["dual-boot" "dualboot-windows"]
      (host.functionalities or []);
  in
    mkEnableOption ''
      Keeps the hardware clock in local time instead of UTC.
      This is particularly important when the system dual-boots with Windows,
      as Windows defaults to local time for the RTC.
    ''
    // {default = useLocalTime;};

  mkLocaleOption = {
    host,
    default ? "en_US.UTF-8",
  }:
    mkOption {
      type = str;
      description = ''
        Configures the default locale settings. This determines:
        - Language for program messages and UI text.
        - Date, time, numeric, and monetary formatting conventions.
        - Character sorting and collation order.

        Applies to all applications that respect locale environment variables.
      '';
      default = host.localization.locale or default;
    };
in
  exports
