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
      inherit getUsers getAdminsUsers getNonServiceUsers;
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

  inherit (attrsets) attrNames filterAttrs genAttrs mapAttrs mapAttrs' mapAttrsToList;
  inherit (filesystem) pathExists readDir entrypoint entrypoints;
  inherit (lists) asList any concatMap elem findFirst length;
  inherit (strings) hasSuffix removeSuffix;
  inherit (types) isFunction;

  candidates = entrypoints.nix.candidates or ["default.nix"];

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

  getUsers = spec: let
    mkGroup = attrs: let
      names = attrNames attrs;
      values = mapAttrs (name: user:
        user
        // {
          inherit name;
          home = user.home or "/home/${name}";
          description = user.description or name;
        })
      attrs;
      count = length names;
    in {inherit names values count;};

    filterByStatus = status: attrs:
      filterAttrs (_: u: (u.enable or true) == (status == "enabled")) attrs;

    filterByRole = wantedRole: attrs:
      filterAttrs (
        _: u: let
          role = u.role or "";
          isNormal = role == "" || role == "user" || role == "normal";
        in
          if wantedRole == "normal"
          then isNormal
          else role == wantedRole
      )
      attrs;

    mkStatusIndex = attrs:
      genAttrs ["enabled" "disabled"] (status: let
        subset = filterByStatus status attrs;
      in
        (mkGroup subset) // {byRole = mkRoleIndex subset;});

    mkRoleIndex = attrs:
      genAttrs ["normal" "administrator" "service" "guest"] (role: let
        subset = filterByRole role attrs;
      in
        (mkGroup subset) // {byStatus = mkStatusIndex subset;});

    users = mapAttrs (_: u:
      {
        role = "user";
        enable = true;
      }
      // u)
    spec;
  in
    (mkGroup users)
    // {
      byStatus = mkStatusIndex users;
      byRole = mkRoleIndex users;
    };

  getAdminsUsers = host:
    (
      if host.users ? values
      then host.users
      else getUsers host.users
    ).byRole.administrator.values;

  getNonServiceUsers = host:
    filterAttrs (_: user: (user.role or "") != "service")
    (
      if host.users ? values
      then host.users
      else getUsers host.users
    ).values;
in
  exports
