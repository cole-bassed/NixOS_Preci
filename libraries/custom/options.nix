{
  attrsets,
  lists,
  options,
  types,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit
        mkEnable
        # mkEnable'
        mkCfg
        mkOpt
        # mkEnableMod
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
  inherit (lists) asList hasAny init last;
  inherit (options) mkOption mkEnableOption;
  inherit (types) nullOr addCheck float str;
  inherit (strings) toSentenceCase;

  mkEnable = {
    name ? null,
    mod ? null,
    leaf ? null,
    description ? null,
    scope ? "core",
    default ? null,
  }: let
    module =
      if name != null && name != ""
      then name
      else if mod != null && mod != ""
      then mod
      else if leaf != null && leaf != ""
      then leaf
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
    mk = condition: mkEnableOption description' // {default = condition;};
  in
    if default != null
    then mk default
    else {
      false = mk false;
      true = mk true;
    };

  # mkEnable' = {
  #   name ? null,
  #   mod ? null,
  #   description ? null,
  #   scope ? "core",
  #   default ? false,
  # }:
  #   (mkEnable {inherit name mod description scope;}).${
  #     if default
  #     then "true"
  #     else "false"
  #   };

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

  # mkEnableMod = {
  #   leaf,
  #   scope,
  #   default ? false,
  # }:
  #   (mkEnable {inherit leaf scope default;}).default;

  /**
  Build standard module args (cfg/opt/enable/etc.) for an option whose
  nesting mirrors its directory nesting.

  Preferred usage (arbitrary depth, mirrors folder structure):
    mkModuleArgs { inherit config top path pkgs host scope; }
    where `path` is a list of segments under `top`, e.g.
    ["interface" "frontend" "dank-material"] for
    dots.interface.frontend.dank-material.

  Back-compat usage (exactly two segments under top):
    mkModuleArgs { inherit config top dom mod pkgs host scope; }
    is equivalent to path = [dom mod] (dom may be null/omitted for a
    single-segment path).

  If both `path` and `dom`/`mod` are supplied, `path` wins.
  */
  mkModuleArgs = {
    config,
    top,
    path ? null,
    dom ? null,
    mod ? null,
    pkgs ? {},
    host ? {},
    users ? {},
    scope ? "core",
  }: let
    segments =
      if path != null
      then path
      else
        (
          if dom != null
          then [dom mod]
          else [mod]
        );

    user = let
      name =
        if scope == "home"
        then config.home.username or null
        else null;
    in
      if name != null
      then (users.${name} or {}) // {inherit name;}
      else {};

    path' = [top] ++ segments;
    leaf = last segments;
    parent = last (init segments);
    configs = {
      main = config;
      leaf = mkCfg {
        inherit config;
        path = path';
      };
      parent = mkCfg {
        inherit config;
        path = init path';
      };
    };
    opt = options:
      mkOpt {
        inherit options;
        path = path';
      };
    base = leaf;
    bin = {
      pkg = pkgs.${leaf} or null;
      name =
        if bin.pkg != null
        then pkgs.${leaf}.NIX_MAIN_PROGRAM or leaf
        else null;
      path =
        if bin.pkg != null
        then "/run/current-system/sw/bin/${bin.name}"
        else null;
    };
    mkName = {pretty ? true}:
      if pretty
      then toSentenceCase leaf
      else leaf;

    cfg = configs.leaf;
    cfgDom = configs.parent;
    mkEnableDefault = {default ? false}:
      (mkEnable {inherit default leaf scope;}).default;
    prettyName = mkName {};
    name = leaf;
  in {
    inherit
      base
      bin
      cfg
      cfgDom
      config
      configs
      host
      leaf
      mkEnableDefault
      mkName
      name
      opt
      parent
      prettyName
      scope
      top
      user
      ;
  };
  # // optionalAttrs (cfg?enable && cfg?package) {
  #   inherit (cfg) enable;
  #   programs.${leaf} = {
  #     inherit (cfg) enable;
  #     # package = pkgs.${leaf} or {};
  #   };
  # };

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
