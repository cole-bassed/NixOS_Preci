{
  lib,
  defaults,
  lists,
  predicates,
}: let
  exports = {
    internal = {
      inherit
        readDirAttrs
        resolveEntrypoint
        importModule
        collectSpecs
        collectNamedSpecs
        collectUserSpecs
        getUsers
        mkEnvVars
        mkHomeUser
        importAll
        mkHomeUsers
        importModules
        importProfiles
        mkCdAliases
        ;
    };
    external = {
      inherit
        mkEnvVars
        mkHomeUser
        collectSpecs
        getUsers
        collectNamedSpecs
        collectUserSpecs
        mkHomeUsers
        importAll
        importModules
        importProfiles
        ;
    };
  };

  inherit (lib.attrsets) attrNames attrValues filterAttrs foldlAttrs genAttrs mapAttrs mapAttrsToList;
  inherit (lib.filesystem0) baseNameOf readDir;
  inherit (lib.lists) concatMap elem findFirst length;
  inherit (lib.trivial) pathExists;
  inherit (lists) asList;
  inherit (predicates) isAttrs isString;

  entrypoint = defaults.entrypoints.nix.main;
  candidates = defaults.entrypoints.nix.candidates;

  readDirAttrs = {
    base,
    ignore ? defaults.ignore,
    predicate ? (name: type: type == "directory"),
  }:
    filterAttrs
    (name: type: predicate name type && !(elem name ignore))
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
    path ? resolveEntrypoint {inherit base name;},
  }:
    import (base + "/${name}/${path}") args;

  # collect { core = [...]; home = [...]; } across all subdirs of base
  collectSpecs = {
    args,
    extraArgs ? {},
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
  }: let
    entries = readDirAttrs {inherit base ignore;};
    specs =
      mapAttrsToList
      (name: _:
        importModule {
          inherit base name;
          args =
            args
            // {
              dom = baseNameOf (toString base);
              mod = name;
            }
            // extraArgs;
        })
      entries;
  in
    genAttrs tags (tag: concatMap (spec: asList (spec.${tag} or null)) specs);

  # collect { <name> = { core = [...]; home = [...]; }; } keyed by subdir name
  # used by profiles so we know which home belongs to which user
  collectNamedSpecs = {
    args,
    extraArgs ? {},
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
  }: let
    entries = readDirAttrs {inherit base ignore;};
  in
    mapAttrs
    (name: _:
      importModule {
        inherit base name;
        args =
          args
          // {
            dom = baseNameOf (toString base);
            mod = name;
          }
          // extraArgs;
      })
    entries;

  # import all files from user.imports, each returns { core = {...}; home = {...}; }
  collectUserSpecs = {
    args,
    user,
  }:
    map
    (fn: import fn {inherit args;})
    (asList (user.imports or null));

  getUsers = declared: let
    # ── group constructor ────────────────────────────────────────────────────
    mkGroup = attrs: let
      names = attrNames attrs;
      values = mapAttrs (name: user: user // {inherit name;}) attrs;
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

    # ── assemble ─────────────────────────────────────────────────────────────

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
    ((getUsers host).normal.raw);

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
            sessionVariables = mkEnvVars "" paths;
            shellAliases = mkCdAliases paths;
          };
          programs.home-manager.enable = true;
        })
      ]
      ++ concatMap
      (spec: asList (spec.home or null))
      (collectUserSpecs user);
  };

  # modules: shared across all users
  # profiles: per-user, keyed by directory name
  importAll = args @ {
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
    extraArgs ? {},
    kind ? "modules",
    ...
  }:
    if kind == "modules"
    then let
      specs = collectSpecs {inherit args base ignore tags extraArgs;};
    in {
      imports = specs.core or [];
      home-manager.sharedModules = specs.home or [];
    }
    else if kind == "profiles"
    then let
      # named so we can wire home to the right user
      byName = collectNamedSpecs {inherit args base ignore tags extraArgs;};
    in {
      # all core specs merged as system imports
      imports = concatMap (profile: asList (profile.core or null)) (attrValues byName);
      # each user gets their own home-manager config
      home-manager.users =
        mapAttrs (
          name: profile: {config, ...}: mkHomeUser {inherit config name profile;}
        )
        byName;
    }
    else throw "Expected kind to be one of [modules profiles], got ${kind}";

  # convenience: importModules is importAll with kind = "modules"
  importModules = args @ {
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
    extraArgs ? {},
    ...
  }:
    importAll (args // {kind = "modules";});

  # convenience: importProfiles is importAll with kind = "profiles"
  importProfiles = args @ {
    base,
    ignore ? defaults.ignore,
    tags ? defaults.tags,
    extraArgs ? {},
    ...
  }:
    importAll (args // {kind = "profiles";});

  # flatten paths attrset into env vars
  # { pictures = { base = "/home/craole/Pictures"; }; }
  # → PICTURES="/home/craole/Pictures"
  mkEnvVars = prefix: attrs:
    foldlAttrs (
      acc: name: value: let
        key = lib.strings.toUpper "${prefix}${
          if prefix == ""
          then name
          else "_${name}"
        }";
      in
        if isAttrs value && value ? base
        then acc // {"${key}" = value.base;} // mkEnvVars key value
        else if isString value
        then acc // {"${key}" = value;}
        else acc
    ) {}
    attrs;

  # generate `cd` aliases from paths
  # { pictures.base = "/home/craole/Pictures"; }
  # → pics = "cd /home/craole/Pictures"
  mkCdAliases = attrs:
    foldlAttrs (
      acc: name: value:
        if isAttrs value && value ? base
        then acc // {"cd${name}" = "cd ${value.base}";}
        else acc
    ) {}
    attrs;
in
  exports
