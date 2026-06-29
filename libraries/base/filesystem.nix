{
  attrsets,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit
        stem
        nest
        getSpecs
        isNixFile
        isDirectory
        isFile
        isNixPath
        ;
      cat = readFile;
      ls = readDir;
      type = readFileType;
      inherit
        (builtins)
        filterSource
        findFile
        storeDir
        storePath
        toPath
        baseNameOf
        dirOf
        path
        pathExists
        readDir
        readFile
        readFileType
        ;
    };
    global = {
      inherit
        mkPaths
        mkPaths'
        resolveDefaultNix
        ;
    };
  };

  inherit
    (builtins)
    attrNames
    concatLists
    elem
    elemAt
    filter
    head
    isAttrs
    isPath
    isString
    listToAttrs
    mapAttrs
    match
    path
    pathExists
    readDir
    readFile
    readFileType
    stringLength
    substring
    tail
    ;
  inherit (strings) hasPrefix hasSuffix matchRegex;
  inherit (attrsets) filterAttrs;

  /**
  Build a normalized pair of path sets — one for the Nix store, one for the
  local filesystem — from an optional source-tree configuration.

  Project-relative paths (those within the project root) appear in both
  `store` and `local`. Absolute paths outside the project root (e.g. home
  directory folders) appear in `local` only — they have no meaningful store
  representation.

  # Type
  ```nix
  mkPaths :: {
    paths ? :: {
      store ? :: Path | { src :: Path; [name :: Path] };
      local ? :: String | { src :: String; [name :: Path | String] };
    };
    store ? :: Path | { src :: Path; [name :: Path] };
    local ? :: String | null;
  } -> {
    store :: { src :: StorePath; [name :: StorePath] };
    local :: { src :: String;    [name :: String]    };
  }
  ```

  # Arguments

  paths
  : Attribute set with optional `store` and `local` sub-attributes used as
    fallbacks when `store` and `local` are not passed directly. Defaults to
    `{ src = ./../../../.; }`.

  store
  : Either a path literal (the Nix store root of the project) or an attribute
    set whose `src` key is a path literal and whose remaining keys are
    project-relative paths to track. Falls back to `paths.store or paths`.
    Only project-relative paths are copied into the `store` output.

  local
  : String representing the local checkout root shown in headers. Falls back
    to `paths.local.src`, then `paths.local`, then `null` — in which case
    `toString store` is used. Extra keys in `paths.local` beyond `src` are
    treated as absolute local-only paths and merged into the `local` output.

  # Dependencies

  Builtins
  : `isAttrs`, `isPath`, `mapAttrs`, `path`, `removeAttrs`,
    `stringLength`, `substring`, `toString`

  attrsets
  : `filterAttrs`

  strings
  : `hasPrefix`

  # Examples
  ```nix
  # Minimal — derive everything from a single path
  mkPaths { paths.src = ./.; }

  # Separate store and local roots
  mkPaths {
    store = ./src;
    local = "/home/user/project";
  }

  # Project-relative stems — appear in both store and local
  mkPaths {
    store = {
      src        = ./.;
      libraries  = ./libraries;
      templates  = ./templates;
    };
    local = "/etc/nixos";
  }
  # => {
  #   store = { src = /nix/store/…-source; libraries = /nix/store/…-source/libraries; … };
  #   local = { src = "/etc/nixos"; libraries = "/etc/nixos/libraries"; … };
  # }

  # Absolute local-only paths — appear in local only, absent from store
  mkPaths {
    store = { src = ./.; libraries = ./libraries; };
    local = {
      src       = "/etc/nixos";
      pictures  = /home/user/Pictures;
      downloads = /home/user/Downloads;
    };
  }
  # => {
  #   store = { src = /nix/store/…-source; libraries = /nix/store/…-source/libraries; };
  #   local = { src = "/etc/nixos"; libraries = "/etc/nixos/libraries";
  #             pictures = "/home/user/Pictures"; downloads = "/home/user/Downloads"; };
  # }
  ```
  */
  mkPaths = {
    paths ? {src = ./../../../.;},
    store ? paths.store or paths,
    local ? paths.local.src or paths.local or null,
  }: let
    _name = "filesystem::mkPaths";
    root = {
      path = store.src or store;
      asStr = toString root.path;
    };

    src = {
      store = path {
        inherit (root) path;
        name = "source";
      };
      local =
        if local == null
        then toString root.path
        else toString local;
    };

    files = let
      raw =
        if isAttrs store
        then removeAttrs store ["src"]
        else {};

      localExtras =
        if isAttrs (paths.local or null)
        then removeAttrs paths.local ["src"]
        else {};

      absolute =
        filterAttrs (
          _: value:
            ! hasPrefix root.asStr (toString value)
        )
        raw;

      relative =
        filterAttrs (
          _: value:
            hasPrefix root.asStr (toString value)
        )
        raw;

      stems =
        mapAttrs (
          _: value:
            substring (stringLength root.asStr) (-1) (toString value)
        )
        relative;
    in {
      store = mapAttrs (_: stem: src.store + stem) stems;
      local =
        mapAttrs (_: stem: src.local + stem) stems
        // mapAttrs (_: toString) absolute
        // mapAttrs (_: toString) localExtras;
    };
  in
    assert if isAttrs paths
    then true
    else throw "${_name}: 'paths' argument must be an attribute set.";
    assert if (isPath store || isAttrs store)
    then true
    else throw "${_name}: 'store' must be a path literal or an attribute set containing file mappings.";
    assert !isAttrs store
    || (store ? src && isPath store.src)
    || throw "${_name}: 'store' set is missing a valid path for 'src'.";
      mapAttrs (name: _: {src = src.${name};} // files.${name}) {
        store = null;
        local = null;
      };

  stem = path: let
    name = baseNameOf (toString path);
    groups = matchRegex "^(.*)\\.nix$" name;
  in
    if groups == null
    then name
    else head groups;

  nest = path: value:
    if path == []
    then value
    else {${head path} = nest (tail path) value;};

  pathType = path:
    if pathExists path
    then let
      matches = match "^(.*)/([^/]+)$" (toString path);
    in
      if matches == null
      then "unknown"
      else let
        parentPath = /. + (elemAt matches 0);
        baseName = elemAt matches 1;
        entries = readDir parentPath;
      in
        entries.${baseName} or "unknown"
    else null;

  isDirectory = path:
    pathType path == "directory";

  isFile = path:
    pathType path == "regular";

  isNixFile = path: let
    pathString = toString path;
  in
    hasSuffix ".nix" pathString;

  resolveDefaultNix = path:
    if isDirectory path
    then path + "/default.nix"
    else if isString path && hasSuffix "/" path
    then path + "default.nix"
    else path;

  isNixPath = path: let
    resolvedPath = resolveDefaultNix path;
  in
    isFile resolvedPath && isNixFile resolvedPath;

  # getSpecs = {
  #   base,
  #   excludes ? ["default"],
  # }: let
  #   _name = "filesystem::getSpecs";
  #   names = attrNames (readDir base);

  #   normalize = name:
  #     if hasSuffix ".nix" name
  #     then
  #       trim {
  #         mode = "end";
  #         pattern = ".nix";
  #         value = name;
  #       }
  #     else name;

  #   isExcluded = name:
  #     elem (normalize name) excludes;

  #   toCandidate = name:
  #     base + "/${name}";
  # in
  #   if isDirectory base
  #   then
  #     map
  #     (name: {
  #       name = normalize name;
  #       input = resolveDefaultNix (toCandidate name);
  #     })
  #     (
  #       filter
  #       (name: (isExcluded name == false) && isNixPath (toCandidate name))
  #       names
  #     )
  #   else throw "${_name}: expected a directory path, got ${toString base}";

  # getSpecs = {
  #   base,
  #   excludes ? ["default"],
  #   depth ? 2,
  # }: let
  #   # _name = "filesystem::getSpecsRecursive";
  #   scan = dir: d: let
  #     names = attrNames (readDir dir);
  #     normalizeName = name: let
  #       suffix = ".nix";
  #       nameLen = stringLength name;
  #       suffixLen = stringLength suffix;
  #     in
  #       if hasSuffix suffix name
  #       then substring 0 (nameLen - suffixLen) name
  #       else name;
  #     isIncluded = name: !(elem (normalizeName name) excludes);
  #     toCandidate = name: dir + "/${name}";
  #   in
  #     if d == 0
  #     then []
  #     else
  #       concatLists (map (
  #           name:
  #             if isIncluded name && isNixPath (toCandidate name)
  #             then [
  #               {
  #                 name = normalizeName name;
  #                 input = resolveDefaultNix (toCandidate name);
  #               }
  #             ]
  #             else if isDirectory (toCandidate name)
  #             then scan (toCandidate name) (d - 1)
  #             else []
  #         )
  #         names);
  # in
  #   scan base depth;
  getSpecs = {
    base,
    excludes ? ["default"],
    depth ? 2,
  }: let
    normalizeName = name: let
      suffix = ".nix";
      nameLen = stringLength name;
      suffixLen = stringLength suffix;
    in
      if hasSuffix suffix name
      then substring 0 (nameLen - suffixLen) name
      else name;

    normalizedExcludes = map normalizeName excludes;
    isIncluded = name: !(elem (normalizeName name) normalizedExcludes);
    toCandidate = dir: name: dir + "/${name}";

    scan = dir: d: let
      names = attrNames (readDir dir);
    in
      if d == 0
      then []
      else
        concatLists (
          map (
            name: let
              candidate = toCandidate dir name;
            in
              if !isIncluded name
              then []
              else if isNixPath candidate
              then [
                {
                  name = normalizeName name;
                  input = resolveDefaultNix candidate;
                }
              ]
              else if isDirectory candidate
              then scan candidate (d - 1)
              else []
          )
          names
        );
  in
    scan base depth;

  mkPaths' = {
    paths ? {src = ./../../../.;},
    store ? paths.store or paths,
    local ? paths.local.src or paths.local or null,
  }: let
    _name = "filesystem::mkPaths";

    # One recursion level. `storeRoot`/`localRoot` are this level's own
    # `src` (as a {path; asStr;} pair, and a string, respectively).
    # `rawStore`/`rawLocal` are the sibling keys (with `src` stripped)
    # contributed by `store` and `paths.local` at this level.
    buildLevel = storeRoot: localRoot: rawStore: rawLocal: let
      allNames = attrNames (rawStore // rawLocal);

      isGroup = name: isAttrs (rawStore.${name} or null) || isAttrs (rawLocal.${name} or null);
      groupNames = filter isGroup allNames;
      leafNames = filter (n: !isGroup n) allNames;

      leafStore = filterAttrs (n: _: elem n leafNames) rawStore;
      leafLocal = filterAttrs (n: _: elem n leafNames) rawLocal;

      isRelative = value: hasPrefix storeRoot.asStr (toString value);

      # leaves in `store`: relative ones get the usual stem treatment
      # (computed off this level's root); absolute ones pass through.
      storeLeafRelative = filterAttrs (_: isRelative) leafStore;
      storeLeafAbsolute = filterAttrs (_: v: !isRelative v) leafStore;

      stems =
        mapAttrs (
          _: v:
            substring (stringLength storeRoot.asStr) (-1) (toString v)
        )
        storeLeafRelative;

      leafStoreOut = mapAttrs (_: stem: storeRoot.path + stem) stems;
      leafLocalFromStore = mapAttrs (_: stem: localRoot + stem) stems;

      # leaves present only under `paths.local` (no `store` counterpart)
      # are absolute local-only overrides, same as the flat case.
      localOnlyNames = filter (n: !(leafStore ? ${n})) (attrNames leafLocal);
      leafLocalOnly = filterAttrs (n: _: elem n localOnlyNames) leafLocal;

      leafLocalOut =
        leafLocalFromStore
        // mapAttrs (_: toString) storeLeafAbsolute
        // mapAttrs (_: toString) leafLocalOnly;

      groupOut = listToAttrs (map (
          name: let
            gStore =
              if isAttrs (rawStore.${name} or null)
              then rawStore.${name}
              else {};
            gLocal =
              if isAttrs (rawLocal.${name} or null)
              then rawLocal.${name}
              else {};

            gStoreSrc =
              if gStore ? src
              then gStore.src
              else if gStore != {}
              then throw "${_name}: nested group '${name}' is missing 'src'."
              else null;

            # a local-only nested group (no store.src) is rooted at
            # the matching stem under storeRoot, mirroring leaves.
            effectiveStoreSrc =
              if gStoreSrc != null
              then gStoreSrc
              else storeRoot.path + ("/" + name);

            gStoreRoot = {
              path = effectiveStoreSrc;
              asStr = toString effectiveStoreSrc;
            };

            gLocalRoot =
              if gLocal ? src
              then toString gLocal.src
              else if isRelative effectiveStoreSrc
              then localRoot + substring (stringLength storeRoot.asStr) (-1) (toString effectiveStoreSrc)
              else toString effectiveStoreSrc;
          in {
            inherit name;
            value = buildLevel gStoreRoot gLocalRoot (removeAttrs gStore ["src"]) (removeAttrs gLocal ["src"]);
          }
        )
        groupNames);

      storeChildren = mapAttrs (_: g: g.store) groupOut;
      localChildren = mapAttrs (_: g: g.local) groupOut;
    in {
      store = {src = storeRoot.path;} // leafStoreOut // storeChildren;
      local = {src = localRoot;} // leafLocalOut // localChildren;
    };

    root = {
      path = store.src or store;
      asStr = toString root.path;
    };

    localSrc =
      if local == null
      then toString root.path
      else toString local;

    rawStore =
      if isAttrs store
      then removeAttrs store ["src"]
      else {};

    rawLocal =
      if isAttrs (paths.local or null)
      then removeAttrs paths.local ["src"]
      else {};
  in
    assert if isAttrs paths
    then true
    else throw "${_name}: 'paths' argument must be an attribute set.";
    assert if (isPath store || isAttrs store)
    then true
    else throw "${_name}: 'store' must be a path literal or an attribute set containing file mappings.";
    assert !isAttrs store
    || (store ? src && isPath store.src)
    || throw "${_name}: 'store' set is missing a valid path for 'src'.";
      buildLevel root localSrc rawStore rawLocal;
in
  exports
