{
  attrsets,
  defaults,
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

  inherit (attrsets) filterAttrs genAttrs mapAttrs mapAttrs' mapAttrsToList;
  inherit (filesystem) pathExists readDir entrypoint entrypoints;
  inherit (lists) asList any concatMap elem findFirst;
  inherit (strings) hasSuffix removeSuffix;
  inherit (types) isFunction;

  candidates = entrypoints.nix or ["default.nix"];

  pathExcludes =
    defaults.excludes.paths or [
      "archive"
      "backup"
      "review"
      "temp"
      "default.nix"
      "flake.nix"
    ];

  readDirAttrs = {
    base,
    excludes ? pathExcludes,
    predicate ? null,
    includeFiles ? false,
  }:
    filterAttrs
    (
      name: type: let
        defaultPredicate =
          if includeFiles
          then type == "directory" || (type == "regular" && hasSuffix ".nix" name && name != "default.nix")
          else type == "directory";
      in
        (
          if predicate != null
          then predicate name type
          else defaultPredicate
        )
        && !(elem name excludes)
        && (
          if type == "directory"
          then any (f: pathExists (base + "/${name}/${f}")) candidates
          else true
        )
    )
    (readDir base);

  resolveEntrypoint = {
    base,
    name,
  }:
    findFirst (f: pathExists (base + "/${name}/${f}")) entrypoint candidates;

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
    excludes ? pathExcludes,
    tags ? defaults.tags,
    includeFiles ? false,
    rawTag ? "core",
  }: let
    entries = readDirAttrs {inherit base excludes includeFiles;};
    specs =
      mapAttrsToList
      (
        name: type: let
          module = importModule {
            inherit base name;
            args =
              args
              // {
                dom = baseNameOf (toString base);
                mod =
                  if type == "regular"
                  then removeSuffix ".nix" name
                  else name;
              }
              // extraArgs;
          };
        in
          if module ? core || module ? home
          then module
          else {${rawTag} = module;}
      )
      entries;
  in
    genAttrs tags (tag: concatMap (spec: asList (spec.${tag} or null)) specs);

  collectNamedSpecs = {
    args ? {},
    extraArgs ? {},
    base,
    excludes ? pathExcludes,
    tags ? defaults.tags,
    rekey ? false,
  }: let
    entries = readDirAttrs {inherit base excludes;};
    raw =
      mapAttrs
      (
        name: _: let
          importedModule = importModule {
            inherit base name;
            args =
              args
              // {
                dom = baseNameOf (toString base);
                mod = name;
                inherit tags;
              }
              // extraArgs;
          };
        in
          importedModule // {tags = (importedModule.tags or []) ++ asList tags;}
      )
      entries;
  in
    if rekey
    then
      mapAttrs' (dirName: spec: {
        name = spec.name or dirName;
        value = spec // {name = spec.name or dirName;};
      })
      raw
    else raw;

  # STREAMLINED: Stripped of profile logic layouts. Purely evaluates modules.
  importAll = args @ {
    base,
    excludes ? pathExcludes,
    tags ? defaults.tags,
    extraArgs ? {},
    includeFiles ? false,
    ...
  }: let
    specs = collectSpecs {inherit args base excludes tags extraArgs includeFiles;};
  in {
    imports = specs.core or [];
    home-manager.sharedModules = specs.home or [];
  };

  importModules = args @ {
    base,
    excludes ? pathExcludes,
    tags ? defaults.tags,
    extraArgs ? {},
    includeFiles ? true,
    ...
  }:
    importAll (args
      // {
        inherit base excludes tags extraArgs includeFiles;
      });
in
  exports
