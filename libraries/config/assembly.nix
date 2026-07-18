{
  api,
  attrsets,
  debug,
  environment,
  filesystem,
  flake,
  lists,
  names,
  paths,
  strings,
  ingestion,
  systems,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit
        # mkRegistry
        # mkRegistryVariables
        # mkAppVariables
        # mkAppBindings
        # mkBindings
        mkConfiguration
        mkConfiguration'
        mkFlake
        mkFlake'
        mkFlakeModules
        mkPaths
        mkSrc
        ;
    };
    global = {inherit mkFlake mkFlake' mkFlakeModules mkConfiguration mkConfiguration' mkSrc;};
  };

  hosts = api.hosts.registry or api.hosts;
  getHostScopes = api.getHostScopes or api.hosts.getScopes;
  inherit
    (attrsets)
    attrNames
    filterAttrs
    genAttrs
    hasAttr
    foldMerge
    mapAttrs
    mapAttrsToList
    mergeAttrsList
    mkNamespaced
    optionalAttrs
    recursiveUpdate
    removeAttrs
    coalesce
    mapParsedOrdered
    extractArgs
    namesOf
    valuesOf
    ;
  inherit (debug) withContext expect;
  inherit (environment) mkSrc;
  inherit (filesystem) mkPaths;
  inherit
    (lists)
    any
    asList
    asListIf
    concatMap
    elem
    filter
    flatten
    foldl'
    groupBy
    hasAny
    init
    last
    uniqueStrings
    unique
    ;
  inherit (ingestion) collectCategories;
  inherit (strings) concat;
  inherit (systems) getClassification getBuilder systemOf;
  inherit (types) isAttrs isBool isEnabled isList isString typeOf;
  inherit (flake.registry.aggregated) overlays packages;

  mkFlakeModules = flake.modules.mkFlakeModules or (flake.modules.mkFlake or (_: []));

  # ╔════════════════════════════════════════════════╗
  # ╠ FLAKE                                          ╣
  # ╚════════════════════════════════════════════════╝
  mkFlake = {
    base,
    mods,
  }: let
    ctx = "mkFlake";
    normalize = value:
      assert withContext {
        name = ctx;
        assertion = isBool value || isAttrs value;
        message = "expected a bool or attrset, got ${typeOf value}";
        context = "normalising path spec in assemble";
      };
        optionalAttrs (isAttrs value) (removeAttrs value ["enable"]);

    resolved = {
      paths = mkPaths {
        store = base.paths.store or (base.paths or (paths.store or null));
        local = base.paths.local or (paths.local or null);
      };
    };
    paths' = removeAttrs resolved.paths.store ["api"];

    enabled =
      filterAttrs (
        name: value:
          assert withContext {
            inherit name;
            assertion = paths' ? ${name};
            message = "'${name}' is not a known path in paths.store. Known paths are [${concat {
              delim = ", ";
              parts = attrNames paths';
            }}]";
            context = "resolving path for '${name}' in assemble";
          };
            (name != "configuration") && (isEnabled value)
      )
      mods;

    outputs = {
      flake = let
        imported =
          mapAttrsToList
          (name: args: import paths'.${name} (base // {args = normalize args;}))
          enabled;
      in
        mergeAttrsList imported;

      configuration =
        optionalAttrs
        (isEnabled (mods.configuration or false))
        (
          mkConfiguration' base {
            modules = {
              core = [resolved.paths.store.configuration];
              home = [];
            };
          }
        );
    };
  in
    outputs.flake // outputs.configuration;

  mkFlake' = base: mods: mkFlake {inherit base mods;};

  # --------------------------------------------------
  # --> Getters & Setters
  # --------------------------------------------------
  set = {
    pkgAliases = host: _final: prev: let
      system = get.system host;
      updated =
        recursiveUpdate
        ((flake.defaults or {}).pkgAliases or {})
        (host.packages.aliases or {});

      fromPrev = path: let
        segments = asList path;
        step = acc: segment:
          if acc == null || !(isAttrs acc) || !(hasAttr segment acc)
          then null
          else acc.${segment};
      in
        foldl' step prev segments;

      fromRegistry = path:
        if isString path && hasAttr path flake.registry
        then (flake.registry.${path}.packages.${system} or {}).default or null
        else null;

      resolve = path: let
        viaPrev = fromPrev path;
      in
        if viaPrev != null
        then viaPrev
        else fromRegistry path;
    in
      genAttrs (attrNames updated) (shortcut: resolve updated.${shortcut});
  };

  get = {
    class = host: host.class or hosts.default.class;
    scopes = getHostScopes;
    nixpkgs = host: let
      name =
        if host.packages.stable or false
        then "nixpkgs-stable"
        else "nixpkgs";
    in
      if hasAttr name (flake.registry or {})
      then flake.registry.${name}
      else flake.registry.nixpkgs;

    system = host: host.system or (host.platform or hosts.default.system);

    pkgs = host: let
      system = get.system host;
      nixpkgs = get.nixpkgs host;
      scopes = get.scopes host;
    in
      import nixpkgs.source.outPath {
        inherit system;
        config = {
          allowUnfree =
            host.packages.allowUnfree or (
              (flake.defaults or {}).allowUnfree or false
            );
          allowBroken =
            host.packages.allowBroken or (
              (flake.defaults or {}).allowBroken or false
            );
        };
        overlays = overlays.select scopes ++ [(set.pkgAliases host)];
      };
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ CONFIGURATION                                  ╣
  # ╚════════════════════════════════════════════════╝
  mkConfiguration = {
    base,
    args ? {},
  }: let
    ctx = "mkConfiguration";

    resolved = mapAttrs (_: host: mkHost {inherit base args host;}) hosts;

    hostsByClass =
      groupBy
      (name: resolved.${name}.class)
      (attrNames resolved);

    build = class: names: let
      classification = getClassification class;
      builder = getBuilder class;
      classes = ["nixos" "darwin"];
    in
      assert withContext {
        name = ctx;
        assertion = elem class classes;
        message = "unknown class '${class}' in host specs, expected one of [${concat {
          delim = ", ";
          parts = classes;
        }}]";
        context = "grouping hosts by class";
      }; {
        ${classification} = genAttrs names (
          name:
            builder
            {inherit (resolved.${name}) modules pkgs specialArgs;}
        );
      };
  in
    foldMerge (mapAttrsToList build hostsByClass);

  mkConfiguration' = base: args: mkConfiguration {inherit base args;};

  mkHost = {
    base,
    args,
    host,
  }: let
    ctx = "mkHost";

    class = get.class host;
    scopes = get.scopes host;
    pkgs = get.pkgs host;

    src = mkSrc {
      inherit host;
      extraArgs =
        recursiveUpdate (expect {
          name = ctx;
          type = "attrs";
          value = base;
          context = "validating base in systems";
        }) (
          optionalAttrs (args != null) (expect {
            name = ctx;
            type = "attrs";
            value = args;
            context = "validating args type in systems";
          })
        );
      libraries = base.libraries or (args.libraries or null);
    };
    top = src.name or (src.names.top or (names.top or names.src));

    specialArgs =
      {
        inherit args host top;
        api = api // {};
        inherit (src) paths;
        mkPkgs = pkgs: pkgs // (packages.${systemOf pkgs} or {});
      }
      // (removeAttrs src ["lib" "name"]);

    modules = let
      modulesFor = class: let
        aggregated = flake.registry.aggregated or {};
        registry = (aggregated.modules or {}).${class} or null;
      in
        if registry != null
        then registry.select scopes
        else mkFlakeModules class;
      core = (modulesFor class) ++ (args.modules.core or []);
      home = {
        environment = {
          pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];
        };

        home-manager = {
          extraSpecialArgs = specialArgs;
          backupFileExtension = concat {
            delim = "-";
            parts = [top "backup"];
          };
          sharedModules = (modulesFor "home") ++ (args.modules.home or []);
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };
    in
      core ++ [home];
  in {inherit class pkgs specialArgs modules;};

  # ╔════════════════════════════════════════════════╗
  # ╠ REGISTRY                                       ╣
  # ╚════════════════════════════════════════════════╝
  mkRegistry = {
    name,
    extra ? {},
    overrides ? {},
    category ? null,
  }: let
    filterByCategory = criterion: set: let
      getMatches = item:
        if criterion == null
        then true
        else let
          items = collectCategories {source = item;};
          criteria = asList criterion;
        in
          any (fc: any (ic: ic == fc) items) criteria;
    in
      if criterion == null
      then set
      else filterAttrs (_: item: getMatches item) set;

    targets = namesOf overrides;

    stripped =
      removeAttrs (removeAttrs api ["default"]) targets;

    source = filterByCategory category (foldMerge [
      stripped
      extra
      overrides
    ]);
  in
    mapAttrs (
      _: env: let
        shared = import (paths.store.api + "/${name}");

        protocol =
          removeAttrs
          (foldMerge [
            (shared.common or {})
            (shared.${env.protocol or "common"} or {})
          ])
          targets;

        applications = let
          ofProtocol =
            if overrides ? applications
            then {}
            else (protocol.applications or {});
          ofEnvironment = env.applications or {};
          allCategories = uniqueStrings (namesOf ofProtocol ++ namesOf ofEnvironment);
        in
          genAttrs allCategories (
            categoryName:
              (ofProtocol.${categoryName} or [])
              ++ (ofEnvironment.${categoryName} or [])
          );

        entry = foldMerge [protocol env] // {inherit applications;};

        updates =
          optionalAttrs (entry ? applications) {
            applications = mkAppBindings {inherit (entry) applications;};
          }
          // optionalAttrs (entry ? bindings) {
            bindings =
              (mkBindings {
                inherit (entry) bindings;
                applications = entry.applications or {};
              }).options;
          }
          // optionalAttrs (entry ? variables) {
            variables = mkRegistryVariables entry;
          };
      in
        entry // updates
    )
    source;

  mkRegistryVariables = registry: let
    commands = let
      sets =
        mapAttrs
        (_: apps: map (app: app.command) apps)
        (registry.applications or {});
    in
      optionalAttrs (sets != {}) (mkAppVariables {inherit sets;});

    bindings = optionalAttrs (registry ? bindings.modifier) {
      MOD = let
        modifier = registry.bindings.modifier;
      in
        if isList modifier
        then
          concat {
            delim = " ";
            parts = unique modifier;
          }
        else modifier;
    };
  in
    bindings // commands // (registry.variables or {});

  mkAppVariables = payload: let
    args = extractArgs {
      args = payload;
      required = ["sets"];
      defaults = {transformation = "POSIX";};
    };
  in
    mkNamespaced {
      inherit (args) transformation;
      sets =
        mapAttrs
        (
          _: commands: let
            secondary = coalesce commands.secondary commands.primary;
            tertiary = coalesce commands.tertiary secondary;
          in {
            "" = commands.primary;
            inherit secondary tertiary;
          }
        )
        (mapParsedOrdered args.sets);
    };

  mkAppBindings = {
    applications,
    modifier ? "SUPER",
  }: let
    format = name: value:
      asList modifier
      ++ (asListIf (name == "launch") ["ALT"])
      ++ asList value;

    resolve = app:
      if app ? bindings && isAttrs app.bindings
      then app // {bindings = mapAttrs format app.bindings;}
      else app;
  in
    mapAttrs
    (
      _: value:
        if isList value
        then map resolve value
        else value
    )
    applications;

  mkBindings = {
    bindings,
    applications ? {},
    modifier ? bindings.modifier or "SUPER",
  }: let
    mod = asList modifier;

    assemble = name: key:
      if name == "modifier"
      then mod
      else if isBool key
      then key
      else if isString key
      then {inherit key mod;}
      else if isList key
      then {
        mod = mod ++ init key;
        key = last key;
      }
      else null;

    resolve = entry:
      if isBool entry || isList entry
      then entry
      else entry.mod ++ [entry.key];

    registry = mapAttrs assemble bindings;

    apps =
      map (app: {
        key = app.bindings.launch;
        mod = mod ++ ["SHIFT" "ALT"];
        action = app.command;
      })
      (
        filter
        (app: app ? bindings.launch && app.bindings.launch != null)
        (flatten (valuesOf applications))
      );

    groups = let
      validated =
        filter
        (name: applications ? ${name} && isString bindings.${name})
        (namesOf bindings);

      tiers = name: let
        apps = mkAppVariables {sets = applications;};
        mk = extraMod: field: {
          key = registry.${name}.key;
          mod = registry.${name}.mod ++ extraMod;
          action = apps.${name}.${field}.command;
        };
      in [
        (mk [] "")
        (mk ["SHIFT"] "secondary")
        (mk ["ALT"] "tertiary")
      ];
    in
      concatMap tiers validated;
  in {
    options = mapAttrs (_: resolve) registry;
    entries = apps ++ groups;
  };
in
  exports
