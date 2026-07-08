{
  attrsets,
  defaults,
  excludes,
  filesystem,
  lists,
  options,
  paths,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      modules = importModules;
      module = importModule;
      all = importAll;
      collect = collectSpecs;
      collectNamed = collectNamedSpecs;
      importAttrs = readDirAttrs;
      resolve = resolveEntrypoint;
      mkModules = importModules;
    };
    global = {
      inherit
        collectNamedSpecs
        collectSpecs
        importAll
        importModule
        importModules
        readDirAttrs
        resolveEntrypoint
        ;
    };
  };

  inherit
    (attrsets)
    attrNames
    filterAttrs
    genAttrs
    isNotEmptyAttr
    mapAttrs
    mapAttrs'
    optionalAttrs
    recursiveUpdate
    setAttrByPath
    ;
  inherit (filesystem) pathExists readDir entrypoint entrypoints;
  inherit (lists) asModuleList any concatMap elem elemAt findFirst length optionals;
  inherit (strings) hasSuffix removeSuffix;
  inherit (options) mkOption;
  inherit (types) isFunction attrs;

  candidates = entrypoints.nix.candidates or ["default.nix"];

  globalExcludes =
    excludes.paths
    or paths.excludes
    or defaults.excludes.paths
    or [
      "_"
      "archive"
      "backup"
      "bootstrap"
      "review"
      "temp"
      "default"
      "default.nix"
      "flake.nix"
    ];

  resolveExcludes = local:
    globalExcludes
    ++ (
      if local == null
      then []
      else if types.isAttrs local
      then local.paths or []
      else local
    );

  readDirAttrs = {
    base,
    excludes ? null,
    includes ? [],
    predicate ? null,
    includeFiles ? false,
  }: let
    excluded = map normalize (resolveExcludes excludes);

    normalize = name: removeSuffix ".nix" name;

    included = map normalize includes;

    isExcluded = name:
      elem (normalize name) excluded;

    isIncluded = name:
      elem (normalize name) included;

    isDefault = name:
      normalize name == "default";

    defaultPredicate = name: type:
      (type == "directory")
      || (
        includeFiles
        && type == "regular"
        && hasSuffix ".nix" name
        && !isDefault name
      );

    hasEntrypoint = name: type:
      if type == "directory"
      then any (f: pathExists (base + "/${name}/${f}")) candidates
      else true;
  in
    filterAttrs
    (
      name: type:
        (
          if predicate != null
          then predicate name type
          else defaultPredicate name type
        )
        && (!isExcluded name || isIncluded name)
        && hasEntrypoint name type
    )
    (readDir base);

  resolveEntrypoint = {
    base,
    name,
  }:
    findFirst
    (f: pathExists (base + "/${name}/${f}"))
    entrypoint
    candidates;

  hasEntrypointDir = base: name:
    any (f: pathExists (base + "/${name}/${f}")) candidates;

  importModule = {
    args ? {},
    base,
    name,
    path ? null,
  }: let
    isDir = (readDir base).${name} == "directory";
    resolved =
      if isDir
      then
        base
        + "/${name}/${
          if path != null
          then path
          else resolveEntrypoint {inherit base name;}
        }"
      else base + "/${name}";
    imported = import resolved;
  in
    if isFunction imported
    then imported args
    else imported;

  # Last two segments of an accumulated path, for back-compat with module
  # files that still destructure `dom`/`mod` directly instead of `path`.
  #   path = []            -> { dom = null; mod = null; }
  #   path = ["a"]         -> { dom = null; mod = "a"; }
  #   path = ["a" "b"]     -> { dom = "a";  mod = "b"; }
  #   path = ["a" "b" "c"] -> { dom = "b";  mod = "c"; }  (only last 2 matter)
  legacyDomMod = path: let
    len = length path;
  in
    if len == 0
    then {
      dom = null;
      mod = null;
    }
    else if len == 1
    then {
      dom = null;
      mod = elemAt path 0;
    }
    else {
      dom = elemAt path (len - 2);
      mod = elemAt path (len - 1);
    };

  collectSpecs = {
    args,
    extraArgs ? {},
    base,
    excludes ? null,
    includes ? [],
    tags ? defaults.tags,
    includeFiles ? false,
    recurse ? false,
    rawTag ? "core",
    # Seed path for this traversal. Callers that are themselves nested
    # (e.g. a directory's default.nix re-entering importModules for its own
    # subtree) should pass their own already-resolved path here so option
    # nesting mirrors directory nesting instead of restarting at this base.
    path ? [],
  }: let
    stem = name:
      if hasSuffix ".nix" name
      then removeSuffix ".nix" name
      else name;

    wrap = module:
      if module ? core || module ? home
      then module
      else {${rawTag} = module;};

    collect = ctxPath: base: let
      entries = readDirAttrs {inherit base excludes includes includeFiles;};
    in
      concatMap (
        name: let
          type = entries.${name};
          name' = stem name;

          path' = ctxPath ++ [name'];
          legacy = legacyDomMod path';

          module = importModule {
            inherit base name;
            args =
              args
              // legacy
              // {
                path = path';
                leaf = name';
              }
              // extraArgs;
          };

          children =
            optionals
            (type == "directory" && !(hasEntrypointDir base name) && recurse)
            (collect path' (base + "/${name}"));
        in
          [(wrap module)] ++ children
      ) (attrNames entries);

    specs = collect path base;
  in
    genAttrs tags (
      tag:
        concatMap
        (spec: asModuleList (spec.${tag} or null))
        specs
    );

  collectNamedSpecs = {
    args ? {},
    extraArgs ? {},
    base,
    excludes ? null,
    includes ? [],
    tags ? defaults.tags,
    includeFiles ? false,
    rekey ? false,
    path ? [],
  }: let
    entries = readDirAttrs {inherit base excludes includes includeFiles;};
    raw =
      mapAttrs
      (
        name: type: let
          mod =
            if type == "regular"
            then removeSuffix ".nix" name
            else name;

          path' = path ++ [mod];
          legacy = legacyDomMod path';

          importedModule = importModule {
            inherit base name;
            args =
              args
              // legacy
              // {
                inherit tags;
                path = path';
                leaf = mod;
              }
              // extraArgs;
          };
        in
          importedModule
          // {tags = (importedModule.tags or []) ++ asModuleList tags;}
      )
      entries;
  in
    if rekey
    then
      mapAttrs' (
        name: spec: let
          mod =
            if hasSuffix ".nix" name
            then removeSuffix ".nix" name
            else name;
        in {
          name = spec.name or mod;
          value = spec // {name = spec.name or mod;};
        }
      )
      raw
    else raw;

  importAll = args @ {
    base,
    excludes ? null,
    includes ? [],
    tags ? defaults.tags,
    extraArgs ? {},
    recurse ? false,
    includeFiles ? false,
    path ? [],
    ...
  }: let
    specs =
      collectSpecs
      {inherit args base excludes includes tags extraArgs includeFiles recurse path;};
  in {
    imports = specs.core or [];
    home-manager.sharedModules = specs.home or [];
  };

  importModules = args @ {
    base,
    data ? extraArgs.registry or {},
    excludes ? null,
    extraArgs ? {},
    includeFiles ? true,
    includes ? [],
    path ? [],
    childPath ? path,
    recurse ? true,
    tags ? defaults.tags,
    top,
    declareRegistry ? false,
    ...
  }: let
    hasData = isNotEmptyAttr data && declareRegistry;

    specs = collectSpecs {
      inherit args base excludes includes tags includeFiles recurse;
      path = childPath;
      extraArgs =
        recursiveUpdate (args.extraArgs or {}) extraArgs
        // optionalAttrs hasData {registry = data;};
    };

    registryModule = {
      options = setAttrByPath ([top] ++ path ++ ["registry"]) (mkOption {
        type = attrs;
        default = data;
        readOnly = true;
      });
    };
    registryModules = optionals hasData [registryModule];
  in {
    imports = (specs.core or []) ++ registryModules;
    home-manager.sharedModules = (specs.home or []) ++ registryModules;
  };
in
  exports
