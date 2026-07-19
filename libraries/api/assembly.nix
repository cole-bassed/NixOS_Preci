{
  api,
  attrsets,
  ingestion,
  lists,
  types,
  paths,
  strings,
  options,
  ...
}: let
  # ╔════════════════════════════════════════════════╗
  # ╠ EXPORTS                                        ╣
  # ╚════════════════════════════════════════════════╝
  exports = {
    scoped = {
      inherit
        mkAppBindings
        mkAppVariables
        mkBindings
        mkRegistry
        mkRegistrySlice
        mkRegistryModule
        mkRegistryModules
        mkRegistryOption
        mkRegistryVariables
        normalizeField
        normalizeFieldName
        filterByCategory
        ;
    };

    global = {
      inherit mkRegistry;
      mkApi = mkRegistry;
      mkApiVariables = mkRegistryVariables;
      mkApiAppVariables = mkAppVariables;
      mkApiAppBindings = mkAppBindings;
      mkApiBindings = mkBindings;
    };
  };

  # ╔════════════════════════════════════════════════╗
  # ╠ IMPORTS                                        ╣
  # ╚════════════════════════════════════════════════╝
  inherit (attrsets) asAttrsIf coalesce extractArgs filterAttrs foldMerge genAttrs mapAttrs mapParsedOrdered mkNamespaced namesOf optionalAttrs removeAttrs setAttrByPath valuesOf;
  inherit (ingestion) collectCategories;
  inherit (lists) any asList asListIf asModule concatMap filter flatten foldl' init last unique;
  inherit (strings) concat;
  inherit (types) attrs isAttrs isBool isList isNotEmpty isString;
  inherit (options) mkOption;

  # ╔════════════════════════════════════════════════╗
  # ╠ UTILITIES                                      ╣
  # ╚════════════════════════════════════════════════╝
  filterByCategory = criterion: set:
    if criterion != null
    then
      filterAttrs (
        _: item: let
          items = collectCategories {source = item;};
          criteria = asList criterion;
        in
          any (fc: any (ic: ic == fc) items) criteria
      )
      set
    else set;

  # ╔════════════════════════════════════════════════╗
  # ╠ REGISTRY                                       ╣
  # ╚════════════════════════════════════════════════╝
  # --------------------------------------------------
  # --> Builder
  # --------------------------------------------------
  mkRegistry = {
    name, #? module name for shared protocol lookup
    raw ? api.${name} or {}, #? base registry map
    extra ? {}, #? additional definitions
    overrides ? {}, #? forced overrides
    category ? null, #? optional category filter
    preProcess ? (x: x), #? run before merging
    postProcess ? (x: x), #? run after merging but before final output
    transformEntry ? (entry: entry), #? transform each final environment entry
    enableProtocol ? true, #? allow protocol check
  }: let
    registry =
      if isNotEmpty raw
      then raw
      else api.${name} or {};
    targets = namesOf overrides;
    stripped = removeAttrs (removeAttrs registry ["default"]) targets;
    merged = foldMerge [
      stripped
      extra
      overrides
    ];
    source = filterByCategory category (preProcess merged);
  in
    mapAttrs (
      _: env: let
        #> Ingest potential shared data
        shared = import (paths.store.api + "/${name}");

        #> Resolve protocol (if necessary)
        protocol = asAttrsIf enableProtocol (
          removeAttrs (foldMerge [
            (shared.common or {})
            (shared.${env.protocol or "common"} or {})
          ])
          targets
        );

        #> Apply user-defined transformations to entry
        rawEntry = foldMerge [protocol env];
        entry = transformEntry rawEntry;

        #> Make specialized updates (if necessary)
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
        postProcess (entry // updates)
    )
    source;

  mkRegistrySlice = {
    registry, # full registry
    category, # string or list of categories
  }:
    filterByCategory category registry;
  # --------------------------------------------------
  # --> WRAPPERS
  # --------------------------------------------------
  mkRegistryOption = registry:
    mkOption {
      type = attrs;
      default = mkRegistry registry;
      readOnly = true;
    };

  mkRegistryModule = {
    registry,
    top ? null,
    path ? null,
    domain ? null,
    name ? "registry",
  }: let
    parent =
      if isNotEmpty domain
      then asList domain
      else if isNotEmpty top && isNotEmpty path
      then (asList top) ++ (asList path)
      else throw "mkRegistryModule: Unable to determine registry domain";
  in
    optionalAttrs (isNotEmpty registry) {
      options = setAttrByPath (parent ++ [name]) (mkRegistryOption registry);
    };

  mkRegistryModules = args: let
    module = mkRegistryModule args;
  in
    asListIf (isNotEmpty module) (asModule module);

  # --------------------------------------------------
  # --> NORMALIZATION
  # --------------------------------------------------
  normalizeField = {
    registry,
    name,
  }: let
    aliasMap = foldl' (
      acc: entryName: let
        entry = registry.${entryName} or {};
        aliases = asList (entry.alias or entry.aliases or []);
      in
        acc // genAttrs aliases (_: entryName)
    ) {} (namesOf registry);

    canonical = aliasMap.${name} or name;
  in {
    name = canonical;
    value = registry.${canonical} or {};
  };

  normalizeFieldName = {
    registry,
    name,
  }:
    (normalizeField {inherit registry name;}).name;

  # --------------------------------------------------
  # --> VARIABLES
  # --------------------------------------------------
  mkRegistryVariables = mkVariables;

  # ╔════════════════════════════════════════════════╗
  # ╠ VARIABLE GENERATION                            ╣
  # ╚════════════════════════════════════════════════╝
  mkVariables = registry: let
    #> Register application commands
    commands = optionalAttrs (registry ? applications) (
      mkAppVariables {
        sets =
          mapAttrs
          (_: apps: map (app: app.command) apps)
          registry.applications;
      }
    );

    #> Register modifier binding (e.g. MOD=...)
    bindings = optionalAttrs (registry ? bindings.modifier) {
      MOD = let
        inherit (registry.bindings) modifier;
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
      sets = mapAttrs (_: cmds: let
        secondary = coalesce cmds.secondary cmds.primary;
        tertiary = coalesce cmds.tertiary secondary;
      in {
        inherit secondary tertiary;
        "" = cmds.primary;
      }) (mapParsedOrdered args.sets);
    };

  mkAppBindings = {
    applications,
    modifier ? ["SUPER"],
    launcher ? ["ALT"],
  }: let
    format = name: value:
      asList modifier
      ++ (asListIf (name == "launch") (asList launcher))
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

  # ╔════════════════════════════════════════════════╗
  # ╠ BINDINGS                                       ╣
  # ╚════════════════════════════════════════════════╝
  mkBindings = {
    bindings,
    applications ? {},
    modifier ? bindings.modifier or ["SUPER"],
    launcher ? ["SHIFT" "ALT"],
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
        mod = mod ++ (asList launcher);
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
