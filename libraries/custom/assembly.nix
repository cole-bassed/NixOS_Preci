{
  attrsets,
  lists,
  types,
  paths,
  ...
}: let
  exports = {
    scoped = {
      inherit
        mkAppBindings
        mkAppVariables
        mkBindings
        mkRegistry
        mkRegistryModule
        mkRegistryModules
        mkRegistryOption
        mkRegistryVariables
        normalizeField
        normalizeFieldName
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

  inherit
    (attrsets)
    coalesce
    extractArgs
    foldMerge
    mapAttrs
    genAttrs
    mapParsedOrdered
    mkNamespaced
    namesOf
    optionalAttrs
    setAttrByPath
    valuesOf
    ;
  inherit
    (lists)
    asList
    asListIf
    asModule
    concatMap
    flatten
    filter
    foldl'
    init
    last
    uniqueStrings
    ;
  inherit (types) attrs isAttrs isBool isList isNotEmpty isString;
  inherit (types) mkOption;

  # ╔════════════════════════════════════════════════╗
  # ╠ REGISTRY                                       ╣
  # ╚════════════════════════════════════════════════╝
  # Compiles the environment variables for a single environment entry
  mkRegistryVariables = entry: let
    applications = entry.applications or {};
    bindings = entry.bindings or {};
    explicit = entry.variables or {};
  in
    foldMerge [
      (optionalAttrs (applications != {}) (mkAppVariables {
        sets = mapAttrs (_: map (app: app.command)) applications;
      }))
      (optionalAttrs (bindings ? modifier) {
        MOD = bindings.modifier;
      })
      explicit
    ];

  # Maps over the registry collection and selectively updates/compiles fields
  mkRegistry = {
    name, #? The module/API name used to fetch shared/common protocols
    extra ? {}, #? Manual/extra definitions to merge on top
    overrides ? {}, #? Forced structural overrides (replaces keys in base if found)
    api, #? Raw input API registry map
  }: let
    #> Pre-process the baseline api to strip out overridden keys.
    #? If a key exists in overrides, we completely discard it from the base API.
    stripped = removeAttrs (removeAttrs api ["default"]) (namesOf overrides);

    #> Safely combine the stripped API baseline with extra definitions
    rawRegistry = foldMerge [
      stripped
      extra
      overrides
    ];
  in
    mapAttrs (
      _envName: env: let
        #> Load the shared protocol definitions for this module
        shared = import (paths.store.api + "/${name}");
        common = shared.common or {};

        #> Strip overridden keys from protocol baseline so they don't leak back in
        baseProtocol = foldMerge [
          common
          (shared.${env.protocol or "common"} or {})
        ];
        protocol = removeAttrs baseProtocol (namesOf overrides);

        #> Resolve Applications (Deep merge application lists, respecting key overrides)
        applications = let
          #> If applications is overridden, we ignore the protocol's defaults
          ofProtocol =
            if overrides ? applications
            then {}
            else (protocol.applications or {});
          ofEnvironment = env.applications or {};

          allCategories = uniqueStrings (namesOf ofProtocol ++ namesOf ofEnvironment);
        in
          genAttrs allCategories (
            category:
              (ofProtocol.${category} or []) ++ (ofEnvironment.${category} or [])
          );

        #> Merge protocol and env safely, with our computed applications resolving last
        entry = foldMerge [protocol env] // {inherit applications;};

        #> Compile the resolved entry's sub-structures (the compiler phase)
        updates =
          optionalAttrs (entry ? applications) {
            applications =
              mkAppBindings {inherit (entry) applications;};
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
    rawRegistry;

  # Wraps the compiled registry in a standard, read-only Nix option schema
  mkRegistryOption = registry:
    mkOption {
      type = attrs;
      default = mkRegistry registry;
      readOnly = true;
    };

  # Generates a single NixOS module structure at a dynamic domain path
  mkRegistryModule = {
    registry,
    top ? null,
    path ? null,
    domain ? null,
    name ? "registry",
  }: let
    _name = "assembly.mkRegistryModule";
    parent = asList {
      value =
        if isNotEmpty domain
        then domain
        else if isNotEmpty top && isNotEmpty path
        then (asList top) ++ (asList path)
        else throw "${_name}: Unable to determine the registry domain";
    };
  in
    optionalAttrs (isNotEmpty registry) {
      options =
        setAttrByPath (parent ++ [name])
        (mkRegistryOption registry);
    };

  # Safe coercion wrapper returning a list of modules (or empty list)
  mkRegistryModules = {
    registry,
    top ? null,
    path ? null,
    domain ? null,
    name ? "registry",
  }: let
    module = mkRegistryModule {
      inherit domain name path registry top;
    };
  in
    asListIf (isNotEmpty module) (asModule module);

  normalizeField = {
    registry,
    name,
  }: let
    aliasMap = foldl' (
      acc: entryName: let
        entry = registry.${entryName};
        aliasesOf = asList (entry.alias or (entry.aliases or []));
      in
        acc // (genAttrs aliasesOf (_: entryName))
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

  # ╔════════════════════════════════════════════════╗
  # ╠ APPLICATIONS                                   ╣
  # ╚════════════════════════════════════════════════╝
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
