{lix}: let
  exports = let
    internal = {
      inherit
        mkEnable
        mkCfg
        mkOpt
        mkEnableMod
        mkModuleArgs
        mkFloatOption
        mkLatitudeOption
        mkLongitudeOption
        ;
    };
    external = {inherit mkModuleArgs;};
  in {inherit internal external;};

  inherit (lix.attrsets) attrByPath setAttrByPath;
  inherit (lix.lists) asList;
  inherit (lix.options) mkOption mkEnableOption;
  inherit (lix.types) isFloat addCheck float;

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
    name,
    description,
    min ? null,
    max ? null,
    default ? null,
  }: let
    check = value:
      isFloat value
      && (
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
    mkOption {
      type = addCheck float check;
      inherit description;
      ${
        if default != null
        then "default"
        else null
      } =
        default;
    };

  mkLatitudeOption = {default ? null}:
    mkFloatOption {
      name = "latitude";
      description = "Latitude coordinate, between -90.0 and 90.0";
      min = -90.0;
      max = 90.0;
      inherit default;
    };

  mkLongitudeOption = {default ? null}:
    mkFloatOption {
      name = "longitude";
      description = "Longitude coordinate, between -180.0 and 180.0";
      min = -180.0;
      max = 180.0;
      inherit default;
    };
in
  exports
