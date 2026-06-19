{
  attrsets,
  paths,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit bat mkPaths toPathList;
      cat = readFile;
      ls = readDir;
      type = readFileType;
    };
    global = {
      inherit
        (builtins)
        baseNameOf
        currentSystem
        dirOf
        filterSource
        findFile
        path
        pathExists
        readDir
        readFile
        readFileType
        storeDir
        storePath
        toPath
        ;
    };
  };

  inherit
    (builtins)
    attrNames
    concatLists
    concatStringsSep
    filter
    isAttrs
    isPath
    isString
    lessThan
    mapAttrs
    path
    readDir
    readFile
    readFileType
    sort
    stringLength
    substring
    typeOf
    ;
  inherit (strings) hasPrefix quote split;
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

  /**
  Split a path or path-like string into its individual components.

  Strips a leading `./` prefix before splitting. The special input `"."` returns
  `["."]` rather than an empty list.

  # Type
  ```nix
  toPathList :: Path   -> [String]
  toPathList :: String -> [String]
  ```

  # Arguments
  path
  : A Nix path literal or a string. Recognised string forms: `"."`,
    `"./rel/path"`, `"rel/path"`, `"/abs/path"`.

  # Examples
  ```nix
  toPathList ./lib/util.nix   # => [ "lib" "util.nix" ]
  toPathList "."              # => [ "." ]
  toPathList "/abs/path"      # => [ "abs" "path" ]
  toPathList "./foo/bar/baz"  # => [ "foo" "bar" "baz" ]
  ```
  */
  toPathList = path: let
    pathStr = toString path;
    clean =
      if hasPrefix "./" pathStr
      then substring 2 (-1) pathStr
      else pathStr;
  in
    if pathStr == "."
    then ["."]
    else filter (x: x != "") (split "/" clean);

  /**
  Read a file, or recursively collect and label all regular files in a directory.

  # Behavior
  - Single file:
    - If `label` is provided, it is shown directly.
    - Else if the input `path` is a string, it is shown directly.
    - Else if `root` is provided, the file is shown relative to `root`.
    - Else the absolute/normalised Nix path string is shown.
  - Directory:
    - Walks recursively in lexicographic order.
    - If `root` is provided, every file is shown relative to `root`.
    - Else every file is shown relative to the walked directory.

  Path headers use this format:

  ```
  #************************************************
  #> STORE: /nix/store/…-source
  #> LOCAL: /path/to/flake
  #> STEMS: [ "relative" "path" "parts" "file.nix" ]
  #************************************************
  ```

  When store and local roots are identical, a single `#> ROOT:` line is shown
  instead of the `STORE` / `LOCAL` pair.

  Symlinks and unknown filesystem entries are silently skipped.

  # Type
  ```nix
  bat :: Path -> String
  bat :: String -> String
  bat :: {
    path       :: Path | String;
    root      ?: Path | String | { store :: Path; local :: Path | String };
    label     ?: String;
    name      ?: String;   # alias for label
  } -> String
  ```

  # Arguments
  path
  : A path literal or path-like string pointing to a file or directory.
    Accepted string prefixes: `/`, `./`, `../`, `~/`.

  root
  : Override the root used to compute relative labels and the header.
    Accepts a path literal, a `{ store, local }` pair, or anything accepted
    by `mkPaths`. Defaults to the module-level `paths`.

  label
  : Explicit label shown in the path header instead of the computed relative
    path. Also accepted as `name`.

  # Examples
  ```nix
  # Single file — short form
  bat ./config.nix

  # Whole directory
  bat ./lib

  # Explicit label
  bat { path = ./src/main.nix; label = "main entry point"; }

  # Custom root so headers are relative to ./src
  bat { path = ./src/util.nix; root = ./src; }

  # Store/local root pair
  bat {
    path = ./src/util.nix;
    root = { store = ./.; local = "/home/user/project"; };
  }
  ```
  */
  bat = input: let
    _name = "filesystem::bat";

    args =
      if isAttrs input
      then input
      else {path = input;};

    path = let
      candidate = args.path;
      isValidString =
        isString candidate
        && (
          false
          || hasPrefix "/" candidate
          || hasPrefix "./" candidate
          || hasPrefix "../" candidate
          || hasPrefix "~/" candidate
        );
    in
      if isPath candidate || isValidString
      then candidate
      else
        throw "${_name}: expected `path` to be a path or path-like string, got ${
          typeOf candidate
        }: ${toString candidate}";

    root = let
      candidate = args.root or null;
    in
      if candidate == null
      then mkPaths {inherit paths;}
      else if isAttrs candidate && (candidate ? store || candidate ? local)
      then
        mkPaths {
          store = candidate.store or candidate.local;
          local = candidate.local or toString candidate.store;
        }
      else mkPaths {store = candidate;};

    label = args.label or (args.name or null);

    toRelativePath = activeRoot: targetPath: let
      targetStr = toString targetPath;
      baseStr =
        if hasPrefix activeRoot.store.src targetStr
        then activeRoot.store.src
        else activeRoot.local.src;
    in
      if targetStr == baseStr
      then "."
      else if hasPrefix baseStr targetStr
      then "./" + substring (stringLength baseStr + 1) (-1) targetStr
      else "./" + targetStr;

    mkHeader = shownPath:
      concatStringsSep "\n" (
        ["#************************************************"]
        ++ (
          if root.store.src != root.local.src
          then [
            "#> STORE: ${root.store.src}"
            "#> LOCAL: ${root.local.src}"
          ]
          else ["#>  ROOT: ${root.local.src}"]
        )
        ++ ["#> STEMS: ${quote (toPathList shownPath)}"]
        ++ ["#************************************************"]
      );

    fileBlock = shown: child:
      mkHeader shown + "\n" + readFile child;

    collectFiles = displayRoot: dir: let
      entries = readDir dir;
      names = sort lessThan (attrNames entries);
    in
      concatLists (map (
          name: let
            child = dir + "/${name}";
            shown =
              if displayRoot != null
              then toRelativePath displayRoot child
              else toRelativePath root child;
          in
            if entries.${name} == "regular"
            then [(fileBlock shown child)]
            else if entries.${name} == "directory"
            then collectFiles displayRoot child
            else []
        )
        names);

    shownPath =
      if label != null
      then label
      else if isString path
      then path
      else toRelativePath root path;

    displayRoot =
      if readFileType path == "directory"
      then root
      else null;
  in
    if readFileType path == "directory"
    then concatStringsSep "\n\n" (collectFiles displayRoot path)
    else fileBlock shownPath path;
in
  exports
