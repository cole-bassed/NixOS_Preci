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
    global = {
      inherit mkModuleArgs;
    };
  };

  inherit (attrsets) attrByPath genAttrs mkNamespaced optionalAttrs recursiveUpdate setAttrByPath;
  inherit (lists) asList elem hasAny head init last;
  inherit (options) mkOption mkEnableOption;
  inherit (types) nullOr addCheck float str;
  inherit (strings) toSentenceCase concatStringsSep;

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
    options ? {},
    top,
    path ? null,
    dom ? null,
    mod ? null,
    pkgs ? {},
    host ? {},
    users ? {},
    scope ? "core",
  }: let
    targets = [
      "main"
      "custom"
      "domain"
      "parent"
      "module"
    ];

    paths = let
      segments =
        if path != null
        then path
        else
          (
            if dom != null
            then [dom mod]
            else [mod]
          );
    in {
      validate = path: target:
        if path != null
        then path
        else if elem target targets
        then paths.${target}
        else throw "Invalid target: '${target}'. Valid targets are: ${concatStringsSep ", " targets}";

      main = [];
      custom = [top];
      module = paths.custom ++ segments;
      parent = init paths.module;
      domain = paths.custom ++ [(head segments)];
    };

    get = {
      inherit host scope paths;

      config = genAttrs targets (
        target: set.config {inherit target;}
      );

      options = genAttrs targets (
        target: attrByPath (asList (paths.validate null target)) {} options
      );

      top =
        if top != null
        then top
        else get.names.custom;

      dom =
        if dom != null
        then dom
        else get.names.domain;

      names =
        genAttrs targets (
          target: let
            path = paths.validate null target;
          in
            if path != []
            then last path
            else "main"
        )
        // {
          user =
            get.config.main.home.username or (
              get.config.custom.users.primary.name or null
            );
        };
      name = get.names.module;
      prettyName = set.name {pretty = true;};

      user = let
        name = get.names.user;
      in
        optionalAttrs (name != null)
        ((users.${name} or {}) // {inherit name;});

      package = pkgs.${get.name} or null;
    };

    set = {
      config = {
        target ? "module",
        path ? null,
        extra ? {},
      }:
        attrByPath
        (asList (paths.validate path target))
        {}
        (recursiveUpdate config extra);
      options = genAttrs targets (
        target: args: let
          hasPath = args ? path || args ? extra;
          extra =
            if hasPath
            then (args.extra or {})
            else args;
          path = args.path or null;
        in
          setAttrByPath (asList (paths.validate path target)) extra
      );

      enable = {default ? false}:
        mkEnable {
          inherit (get) scope name;
          inherit default;
        };

      name = {
        name ? get.names.module,
        pretty ? true,
      }:
        if pretty
        then toSentenceCase name
        else name;

      bin = {
        module ? get.names.module,
        package ? get.package,
      }: let
        name =
          if package != null
          then package.NIX_MAIN_PROGRAM or module
          else null;
        path =
          if package != null
          then "/run/current-system/sw/bin/${module}"
          else null;
      in {inherit package name path;};
    };
  in
    (mkNamespaced {inherit get set;})
    // get
    // {inherit get set;};

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
