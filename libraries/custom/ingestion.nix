{
  attrsets,
  defaults,
  excludes,
  filesystem,
  lists,
  paths,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      module = importModule;
      all = importAll;
      collect = collectSpecs;
      collectNamed = collectNamedSpecs;
      importAttrs = readDirAttrs;
      resolve = resolveEntrypoint;
      inherit collectFields collectAliases collectCategories;
    };
    global = {
      inherit
        collectNamedSpecs
        collectSpecs
        importAll
        importModule
        readDirAttrs
        resolveEntrypoint
        ;
    };
  };

  inherit
    (attrsets)
    attrNames
    attrByPath
    filterAttrs
    genAttrs
    mapAttrs
    mapAttrs'
    ;
  inherit (filesystem) pathExists readDir entrypoint entrypoints;
  inherit (lists) asListIf asModuleList any concatMap elem findFirst asList;
  inherit (strings) hasSuffix removeSuffix;
  inherit (types) isFunction isNotEmpty;

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

          module = importModule {
            inherit base name;
            args =
              (removeAttrs args ["excludes" "includes"])
              // {
                path = path';
                leaf = name';
              }
              // extraArgs;
          };

          children =
            asListIf
            (type == "directory" && !(hasEntrypointDir base name) && recurse)
            name;
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

          importedModule = importModule {
            inherit base name;
            args =
              args
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

  # Collect values for multiple keys from a (possibly nested) attribute set
  collectFields = {
    source ? null,
    name ? null,
    keys ? [],
  }: let
    target =
      if isNotEmpty name
      then attrByPath (asList name) null source
      else source;
  in
    asListIf (isNotEmpty target) (
      concatMap
      (key: asList (target.${key} or null))
      (asList keys)
    );

  collectAliases = args:
    collectFields {
      source = args.source or null;
      name = args.name or null;
      keys = (args.keys or []) ++ ["alias" "aliases"];
    };

  collectCategories = args:
    collectFields {
      source = args.source or null;
      name = args.name or null;
      keys = (args.keys or []) ++ ["category" "categories"];
    };
in
  exports
