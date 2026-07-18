{
  assembly,
  attrsets,
  lists,
  options,
  defaults,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit
        mkAppOption
        mkAppOptions
        mkBindOption
        mkBindOptions
        mkEnable
        mkFloatOption
        mkGeoProviderOption
        mkLatitudeOption
        mkLocalTimeOption
        mkLocaleOption
        mkLongitudeOption
        mkRegistryOptions
        mkTimezoneOption
        mkVarOptions
        ;
    };
    global = {};
  };

  inherit (assembly) mkAppBindings mkBindings mkRegistryVariables;
  inherit (attrsets) mapAttrs optionalAttrs recursiveUpdate;
  inherit (lists) asList hasAny;
  inherit (options) mkOption mkEnableOption;
  inherit
    (types)
    attrsOf
    bool
    nullOr
    nullPkg
    addCheck
    either
    float
    isNotEmpty
    listOf
    str
    submodule
    ;

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

  # Shared shape for grouping per-item options into one submodule option.
  mkGroupedOptions = {
    name,
    items,
    option,
    description,
  }: {
    ${name} = mkOption {
      inherit description;
      type = submodule {options = mapAttrs (item: _: option item) items;};
      default = {};
    };
  };

  # Shared shape for a single resolved-from-registry option.
  mkRegistryOption = {
    name,
    type,
    label ? null,
    labels ? {},
    prefix,
    noun,
    registry,
  }: let
    labels' = recursiveUpdate defaults.labels.application labels;
  in
    mkOption {
      inherit type;
      default = registry.${name} or null;
      description = "${prefix} ${(
        if label != null
        then label
        else (labels'.${name} or "${name} ${noun}")
      )} from the registry.";
    };

  mkRegistryOptions = registry:
    {}
    // optionalAttrs (registry ? variables || registry ? applications)
    (mkVarOptions {variables = mkRegistryVariables registry;})
    // optionalAttrs (registry ? bindings)
    (mkBindOptions {inherit (registry) bindings;})
    // optionalAttrs (registry ? applications)
    (mkAppOptions {inherit (registry) applications;});

  mkAppOption = {
    name,
    scope ? "user",
    package ? null,
    apiOr ? (_: null),
    # Registry-only arguments
    label ? null,
    labels ? {},
    applications ? [],
    modifier ? "SUPER",
    type ? null,
    ...
  } @ args: let
    enableOverride = apiOr "enable";

    # Base Module options
    resolved = {
      base = {
        enable = mkEnable {
          inherit name scope;
          default = enableOverride == true;
        };

        package = mkOption {
          type = nullPkg;
          default = package;
          description = "Package backing the '${name}' application.";
        };

        protocol = mkOption {
          type = nullOr (types.enum ["wayland" "x11"]);
          default = apiOr "protocol";
          description = "Display protocol required by '${name}', if any.";
        };

        category = mkOption {
          type = listOf str;
          default = asList (apiOr "category");
          description = "Registry category tag(s) for '${name}' (e.g. \"frontend\", \"backend\", \"greeter\").";
        };

        configType = mkOption {
          type = nullOr (types.enum ["hyprlang" "lua" "kdl" "conf"]);
          default = apiOr "configType";
          description = "Native configuration file format used by '${name}', if it has one.";
        };
      };

      binding = {
        name = mkOption {
          type = str;
          description = "Registry name of the resolved application entry.";
        };
        description = mkOption {
          type = nullOr str;
          default = null;
          description = "Human-readable description for the resolved application entry.";
        };
        command = mkOption {
          type = str;
          description = "The executable/binary command used to trigger it.";
        };
        bindings = mkOption {
          type = attrsOf (listOf str);
          default = {};
          description = "Binding keys normalized to list format like { launch = [ 'V' ]; }";
        };
      };
    };
    submoduleSchema = {
      options = resolved.base // resolved.binding;
    };
  in
    if !(args ? applications)
    then resolved.base
    else
      mkRegistryOption {
        inherit name label labels;
        prefix = "Ordered list of";
        noun = "applications";
        registry = mkAppBindings {inherit applications modifier;};
        type =
          if isNotEmpty type
          then type
          else nullOr (listOf (submodule submoduleSchema));
      };

  mkAppOptions = {
    applications,
    labels ? {},
    type ? null,
    name ? "applications",
    ...
  }:
    mkGroupedOptions {
      inherit name;
      items = applications;
      option = name:
        mkAppOption {
          inherit applications labels name type;
          isRegistry = true;
        };
      description = "Priority-ordered tier applications resolved by the registry.";
    };

  mkBindOption = {
    name,
    type ? null,
    label ? null,
    labels ? {},
    bindings,
  }:
    mkRegistryOption {
      inherit name label labels;
      prefix = "Binding key for";
      noun = "binding";
      registry = (mkBindings {inherit bindings;}).options;
      type =
        if isNotEmpty type
        then type
        else either (listOf str) bool;
    };

  mkBindOptions = {
    bindings,
    labels ? {},
    type ? null,
    name ? "bindings",
  }:
    mkGroupedOptions {
      inherit name;
      items = bindings;
      option = itemName:
        mkBindOption {
          inherit bindings labels type;
          name = itemName;
        };
      description = "Hotkey trigger bindings resolved by the registry.";
    };

  mkVarOptions = {
    variables,
    name ? "variables",
    type ? str,
  }:
    mkGroupedOptions {
      inherit name;
      items = variables;
      option = key:
        mkOption {
          inherit type;
          default = variables.${key};
          description = "Variable '${key}' resolved by the registry.";
        };
      description = "Custom configuration variables.";
    };
in
  exports
