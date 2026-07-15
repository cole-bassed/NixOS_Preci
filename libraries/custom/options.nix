{
  assembly,
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
        mkAppOptions
        mkAppOption
        mkBindOptions
        mkBindOption
        # mkEnableMod
        mkFloatOption
        mkRegistryOptions
        mkLatitudeOption
        mkLongitudeOption
        mkVarOptions
        mkGeoProviderOption
        mkTimezoneOption
        mkLocalTimeOption
        mkLocaleOption
        ;
    };
    global = {inherit mkModuleArgs;};
  };

  inherit (assembly) mkAppBindings mkBindings mkRegistryVariables;
  inherit
    (attrsets)
    asAttrs
    attrByPath
    attrValues
    foldMerge
    genAttrs
    hasAttr
    valuesOf
    namesOf
    mapAttrs
    mkNamespaced
    optionalAttrs
    recursiveUpdate
    setAttrByPath
    ;
  inherit
    (lists)
    asList
    elem
    hasAny
    head
    init
    last
    optionals
    ;
  inherit (options) mkOption mkEnableOption;
  inherit
    (types)
    attrsOf
    bool
    nullOr
    addCheck
    either
    float
    isNotEmpty
    listOf
    str
    submodule
    ;
  inherit (strings) toSentenceCase concatStringsSep;

  _defaults = {
    labels = {
      browser = "Browser launch";
      editor = "Editor launch";
      visual = "Visual/IDE launch";
      launcher = "Launcher trigger";
      terminal = "Terminal launch";
    };
  };

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
    api ? lib.api or (lix.api or {}),
    config ? {},
    defaults ? {},
    host ? {},
    hostPath ? path,
    lib ? {},
    lix ? {},
    options ? {},
    osConfig ? {},
    path,
    pkgs ? {},
    # registry ? null,
    scope ? "core",
    selection ? null,
    top ? null,
    userPath ? path,
    users ? api.users.getInteractiveUsers host,
  }: let
    targets = ["main" "custom" "domain" "parent" "module"];
    # selection = spec: selectionOf {inherit top spec registry;};

    validate = {
      path = target:
        if elem target targets
        then paths.${target}
        else
          throw "Invalid target: '${target}'. Valid targets are: ${
            concatStringsSep ", " targets
          }";
    };

    names =
      genAttrs targets (
        target: let
          check = validate.path target;
        in
          if check != []
          then last check
          else "main"
      )
      // {
        user =
          get.config.main.home.username or (
            get.config.custom.users.primary.name or null
          );
        package = pkg.name or null;
      };

    # pkgName may be a flat string ("gitFull") or a nested path
    # (["llm-agents" "claude-code"]) — normalize to a list either way.
    pkg = let
      name' = get.apiOr "package";
      path' =
        if name' != null
        then asList name'
        else [get.name];
    in {
      path = path';
      name = last path';
      spec = attrByPath path' null pkgs;
    };

    base =
      if top != null
      then top
      else names.custom;

    paths = {
      validate = validate.path;
      main = [];
      custom = [base];
      module = paths.custom ++ path;
      parent = init paths.module;
      domain = paths.custom ++ [(head path)];
    };

    get = {
      inherit host scope names paths users;
      name = names.module;
      prettyName = set.name {pretty = true;};

      user = let
        name = names.user;
      in
        optionalAttrs
        (name != null)
        ((users.${name} or {}) // {inherit name;});

      top =
        if top != null
        then top
        else names.custom;

      config =
        genAttrs targets
        (target: set.config {inherit target;});
      cfg = get.config.module;
      cfgOr = key: let
        fromConfig = attrByPath (paths.module ++ [key]) null config;
      in
        if fromConfig != null
        then fromConfig
        else
          attrByPath
          (paths.module ++ [key]) (defaults.${key} or null)
          osConfig;

      options =
        genAttrs targets
        (target: attrByPath (paths.validate target) {} options);

      enabled = {
        criteria ? elem (host.type or "laptop") ["desktop" "laptop"],
        selectFrom ? set.selection,
      }: let
        materialize = selected:
          mapAttrs
          (_: extra: {enable = true;} // extra)
          (foldMerge selected);

        required = let
          byHost = [(selectFrom host)];
          byUser =
            optionals
            criteria
            (map selectFrom (attrValues users));
        in {
          core = materialize (byHost ++ byUser);
          home =
            materialize
            (byHost ++ (optionals criteria [(selectFrom get.user)]));
        };
      in
        hasAttr get.name required.${scope};

      package = pkg.spec;
      pkgName = pkg.name;
      pkgPath = pkg.path;

      hostEntry = attrByPath hostPath {} host;
      userEntry = attrByPath userPath {} get.user;
      dataEntry = genAttrs targets (
        target: let
          #TODO This is not making use of our target and genAttrs style setup
          domain = head path;
          name = last path;
          registry =
            if target == "module"
            then api.${domain}.registry.${name} or {}
            else if target == "domain"
            then api.${domain}.registry or {}
            else if target == "custom"
            then api.custom.registry or {}
            else if target == "main"
            then api.main.registry or {}
            else {};
        in {
          inherit registry;
          names = namesOf registry;
          values = valuesOf registry;
          select = asAttrs; # TODO: This is not working at all
        }
      );
      apiOr = key:
        get.hostEntry.${key} or
            (get.userEntry.${key} or
              (get.dataEntry.module.registry.${key} or
                (get.dataEntry.parent.registry.${key} or
                  (get.dataEntry.domain.registry.${key} or
                    (get.dataEntry.custom.registry.${key} or
                      (get.dataEntry.main.registry.${key} or null))))));
    };

    set = {
      config = {
        target ? "module",
        extra ? {},
      }: let
        targetPath = paths.validate target;
      in
        attrByPath targetPath {} (
          recursiveUpdate config
          (setAttrByPath targetPath extra)
        );

      options =
        genAttrs
        targets (target: extra: setAttrByPath (paths.validate target) extra);
      opt = set.options.module;

      name = {
        name ? names.module,
        pretty ? true,
      }:
        if pretty
        then toSentenceCase name
        else name;
      enable = {default ? false}:
        mkEnable {
          inherit (get) scope name;
          inherit default;
        };
      package = mkOption {
        type = with types; nullOr package;
        default = get.package;
        description = "Package backing the ${get.prettyName} compositor component.";
      };

      selection = spec:
        if selection != null
        then selection spec
        else asAttrs spec;

      bin = {
        module ? names.module,
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
    labels' = recursiveUpdate _defaults.labels labels;
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
    (mkBindOptions {bindings = registry.bindings;})
    // optionalAttrs (registry ? applications)
    (mkAppOptions {applications = registry.applications;});

  mkAppOption = {
    name,
    type ? null,
    label ? null,
    labels ? {},
    applications,
    modifier ? "SUPER",
  }: let
    mod = {
      options = {
        name = mkOption {
          type = str;
          description = "Package name or lookup identifier.";
        };
        description = mkOption {
          type = str;
          description = "Human-readable descriptive label.";
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
  in
    mkRegistryOption {
      inherit name label labels;
      prefix = "Ordered list of";
      noun = "applications";
      registry = mkAppBindings {inherit applications modifier;};
      type =
        if isNotEmpty type
        then type
        else nullOr (listOf (submodule mod));
    };

  mkAppOptions = {
    applications,
    labels ? {},
    type ? null,
    name ? "applications",
  }:
    mkGroupedOptions {
      inherit name;
      items = applications;
      option = name: mkAppOption {inherit applications labels name type;};
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
