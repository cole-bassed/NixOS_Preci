{
  attrsets,
  config,
  defaults,
  environment,
  filesystem,
  lists,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit (config) mkDots;
      inherit
        collectNamedSpecs
        collectSpecs
        getUsers
        importAll
        importModule
        importModules
        importProfiles
        mkHomeUser
        mkHomeUsers
        readDirAttrs
        resolveEntrypoint
        ;
    };
    global = {
      inherit
        collectNamedSpecs
        collectSpecs
        getUsers
        importAll
        importModule
        importModules
        importProfiles
        mkHomeUser
        mkHomeUsers
        readDirAttrs
        resolveEntrypoint
        ;
    };
  };

  inherit (attrsets) namesOf valuesOf filterAttrs genAttrs mapAttrs mapAttrs' mapAttrsToList;
  inherit (entrypoints.nix) candidates;
  inherit (environment) mkVariables mkCdAliases;
  inherit (filesystem) pathExists readDir entrypoint entrypoints;
  inherit (lists) asList any concatMap elem findFirst length;
  inherit (strings) hasSuffix;
  inherit (types) isFunction;

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
    (name: type: let
      defaultPredicate =
        if includeFiles
        then
          type
          == "directory"
          || (type == "regular" && hasSuffix ".nix" name && name != "default.nix")
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
      ))
    (readDir base);

  # find the first candidate that exists under base/name/, fall back to entrypoint
  resolveEntrypoint = {
    base,
    name,
  }:
    findFirst
    (f: pathExists (base + "/${name}/${f}"))
    entrypoint
    candidates;

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

  # collect { core = [...]; home = [...]; } across all subdirs of base
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
                  then strings.removeSuffix ".nix" name
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
    tags ? defaults.tags, # Passed from the parent loader (e.g., [ "core" ] or [ "home" ])
    rekey ? false,
  }: let
    entries = readDirAttrs {inherit base excludes;};
    raw =
      mapAttrs
      (name: _: let
        # Evaluate the underlying nix module configuration file
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
        importedModule
        // {
          tags =
            (importedModule.tags or [])
            ++ asList tags;
        })
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

  getUsers = declared: let
    # ── group constructor ────────────────────────────────────────────────────
    mkGroup = attrs: let
      names = namesOf attrs;
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

    # ── filter helpers ───────────────────────────────────────────────────────

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

    # ── cross-cutting group index ────────────────────────────────────────────
    # byStatus and byRole are mutually enriched: each slice gets the other
    # dimension attached, so callers can do .byStatus.enabled.byRole.admin etc.

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
    declared;
  in
    (mkGroup users)
    // {
      byStatus = mkStatusIndex users;
      byRole = mkRoleIndex users;
    };

  mkHomeUsers = host:
    mapAttrs (_: user: {
      config,
      osConfig,
      top,
      ...
    }:
      mkHomeUser {inherit user config osConfig top;})
    (getUsers host).normal.raw;

  mkHomeUser = {
    user,
    config,
    osConfig,
    top,
  }: {
    imports =
      [
        (let
          paths = config.${top}.paths or {};
        in {
          home = {
            inherit (osConfig.system) stateVersion;
            sessionVariables = mkVariables "" paths;
            shellAliases = mkCdAliases paths;
          };
          programs.home-manager.enable = true;
        })
      ]
      ++ (user.imports or []);
  };

  # modules: shared across all users
  # profiles: per-user, keyed by directory name
  importAll = args @ {
    base,
    excludes ? pathExcludes,
    tags ? defaults.tags,
    extraArgs ? {},
    includeFiles ? false,
    kind ? "modules",
    ...
  }:
    if kind == "modules"
    then let
      specs = collectSpecs {inherit args base excludes tags extraArgs includeFiles;};
    in {
      imports = specs.core or [];
      home-manager.sharedModules = specs.home or [];
    }
    else if kind == "profiles"
    then let
      byName = collectNamedSpecs {inherit args base excludes tags extraArgs;};
    in {
      imports = concatMap (profile: asList (profile.core or null)) (valuesOf byName);
      home-manager.users =
        mapAttrs (
          name: profile: {config, ...}: mkHomeUser {inherit config name profile;}
        )
        byName;
    }
    else throw "Expected kind to be one of [modules profiles], got ${kind}";

  # convenience: importModules is importAll with kind = "modules"
  # TODO: Update libraries/internal loaders to parse regular files (.nix).
  # Currently, file nodes are skipped by readDirAttrs or dropped by
  # importModule because it searches for a nested default.nix.
  importModules = args @ {
    base,
    excludes ? pathExcludes,
    tags ? defaults.tags,
    extraArgs ? {},
    includeFiles ? false,
    ...
  }:
    importAll (args
      // {
        inherit base excludes tags extraArgs includeFiles;
        kind = "modules";
      });

  importProfiles = args @ {
    base,
    excludes ? pathExcludes,
    tags ? defaults.tags,
    extraArgs ? {},
    ...
  }:
    importAll (args
      // {
        kind = "profiles";
        inherit base excludes tags extraArgs;
      });
in
  exports
