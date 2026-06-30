# ---------------------------------------------------------------------------
# TODO: Allow flat files (e.g., example.nix) alongside directories.
# Currently, readDirAttrs/importModule drops flat files or expects a directory.
# FIX NEEDED: Modify `readDirAttrs` or wrap this block to check if an entry is
# a "regular" file ending in ".nix". If it is a file, import it directly
# via (base + "/${name}"); if it is a "directory", use the current logic.
# ---------------------------------------------------------------------------
{
  attrsets,
  defaults,
  excludes,
  paths,
  filesystem,
  lists,
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

  inherit (attrsets) attrNames filterAttrs genAttrs mapAttrs mapAttrs';
  inherit (filesystem) pathExists readDir entrypoint entrypoints;
  inherit (lists) asModuleList any concatMap elem findFirst optionals;
  inherit (strings) hasSuffix removeSuffix;
  inherit (types) isFunction;

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
            args = args // {inherit path';} // extraArgs; # pass path' as "path"
          };
          children =
            optionals
            (type == "directory" && (recurse || !(hasEntrypointDir base name)))
            (collect path' (base + "/${name}"));
        in
          [(wrap module)] ++ children
      ) (attrNames entries);
    # collect = ctx: base: let
    #   entries = readDirAttrs {inherit base excludes includes includeFiles;};
    # in
    #   concatMap (
    #     name: let
    #       type = entries.${name};
    #       name' = stem name;

    #       ctx' =
    #         if ctx == null
    #         then {
    #           dom = baseNameOf (toString base);
    #           mod = name';
    #         }
    #         else
    #           ctx
    #           // {
    #             leaf = name';
    #           };

    #       module = importModule {
    #         inherit base name;
    #         args =
    #           args
    #           // ctx'
    #           // extraArgs;
    #       };

    #       children =
    #         optionals
    #         (type == "directory" && (recurse || !(hasEntrypointDir base name)))
    #         (collect ctx' (base + "/${name}"));
    #     in
    #       [(wrap module)] ++ children
    #   ) (attrNames entries);

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

          importedModule = importModule {
            inherit base name;
            args =
              args
              // {
                dom = baseNameOf (toString base);
                inherit mod tags;
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
    ...
  }: let
    specs =
      collectSpecs
      {inherit args base excludes includes tags extraArgs includeFiles recurse;};
  in {
    imports = specs.core or [];
    home-manager.sharedModules = specs.home or [];
  };

  # TODO
  /**
  if directory has default.nix:
    import only directory/default.nix
    do not recursively scan its children here
  else if recurse:
    scan children
  */
  importModules = args @ {
    base,
    excludes ? null,
    includes ? [],
    tags ? defaults.tags,
    extraArgs ? {},
    includeFiles ? true,
    recurse ? true,
    ...
  }: let
    specs =
      collectSpecs
      {inherit args base excludes includes tags extraArgs includeFiles recurse;};
  in {
    imports = specs.core or [];
    home-manager.sharedModules = specs.home or [];
  };
  # importModules = args @ {
  #   base,
  #   excludes ? null,
  #   includes ? [],
  #   tags ? defaults.tags,
  #   extraArgs ? {},
  #   includeFiles ? true,
  #   recurse ? true,
  #   ...
  # }: let
  #   specs =
  #     collectSpecs
  #     {inherit args base excludes includes tags extraArgs includeFiles recurse;};
  # in {
  #   imports = specs.core or [];
  #   home-manager.sharedModules = specs.home or [];
  # };
in
  exports
