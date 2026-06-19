{
  attrsets,
  filesystem,
  lists,
  paths,
  strings,
  comparison,
  types,
  ...
}: let
  exports = {
    scoped = {inherit entrypoint entrypoints mkPaths mkUserPaths bat;};
    global = {
      inherit
        entrypoint
        entrypoints
        mkPaths
        mkUserPaths
        toPathList
        ;
    };
  };

  inherit (lists) filter concatLists head sort optionals;
  inherit (comparison) lessThan;
  inherit (attrsets) attrNames mapAttrs filterAttrs;
  inherit (strings) split' concatStringsSep quote stringLength substring hasPrefix;
  inherit (types) isAttrs isPath isString typeOf;
  inherit (filesystem) path readDir readFile readFileType;

  /**
  Boundary-safe prefix check: true if `value` is exactly `root`, or sits
  *under* `root` separated by a real path boundary ("/"). Plain `hasPrefix`
  would wrongly match "/home/x/dots-backup" against root "/home/x/dots";
  this requires the next character after the prefix to be "/".

  # Type
  ```nix
  isUnder :: (Path|String) -> (Path|String) -> Bool
  ```
  */
  isUnder = root: value: let
    r = toString root;
    v = toString value;
  in
    v == r || hasPrefix (r + "/") v;

  /**
  Classify a single path-like value against the two known roots (the
  project's store src and the host's local src).

  Real Nix path literals are always store-relative by construction -- a
  path value is already copied into the store, so it cannot mean anything
  else, even if it happens to look like it lives under the local root.
  Only strings are ambiguous about which root (if any) they relate to.

  Returns one of:
  - { root = "store";    stem  :: String } -- under (or is) the store root
  - { root = "local";    stem  :: String } -- under the local root
  - { root = "absolute"; value :: String } -- unrelated to either root

  # Type
  ```nix
  classify :: { store :: Path; local :: String } -> (Path|String) -> AttrSet
  ```
  */
  classify = {
    store,
    local,
  }: value: let
    storeAsStr = toString store;
    localAsStr = toString local;
    stemFrom = root: substring (stringLength root) (-1) (toString value);
  in
    if isPath value || isUnder storeAsStr value
    then {
      root = "store";
      stem = stemFrom storeAsStr;
    }
    else if isUnder localAsStr value
    then {
      root = "local";
      stem = stemFrom localAsStr;
    }
    else {
      root = "absolute";
      value = toString value;
    };

  /**
  Build a normalized pair of path sets -- one for the Nix store, one for the
  local filesystem -- from an optional source-tree configuration.

  Every extra key (beyond `src`) in either `store` or `local` is classified
  independently against both roots:

  - Nix path literals, or strings under the store root, get rebased onto
    both `store.src` and `local.src` -- they have a meaningful counterpart
    on both sides.
  - Strings under the local root get rebased onto `local.src`, and mirrored
    onto `store.src` as well, since they describe the same project-relative
    stem just spelled from the local checkout's perspective.
  - Strings under neither root (e.g. "/home/user/Pictures") are genuinely
    absolute, local-only paths -- they appear in `local` verbatim and have
    no `store` entry at all.

  When `local` is an attrset and `meta.usedKey` is given, whichever key
  actually supplied `src` (the first hit in the host's own resolution
  order -- e.g. `src`, then `dots`, then `home`) is excluded from the
  extras. Any *other* key, including `home` or `dots` if they weren't the
  one used to derive `src`, is kept and classified normally -- e.g. a host
  can still define `home` to mean "primary user's home directory" as a
  plain extra, as long as it wasn't also the key chosen to resolve `src`.
  `meta` is resolution bookkeeping only -- it never appears in the output.

  Note: `mkPaths` has no concept of "users" -- it only classifies and
  rebases path-like values it's handed. Deriving defaults like `pictures`
  or `downloads` from a user record is a separate policy concern; see
  `mkUserPaths` below, which produces a plain attrset you can merge into
  `local` before calling this function.

  # Type
  ```nix
  mkPaths :: {
    store ? :: Path | { src :: Path; [name :: Path | String] };
    local ? :: String | { src :: String; [name :: Path | String] };
    meta ? :: { usedKey :: String? };
  } -> {
    store :: { src :: StorePath; [name :: StorePath] };
    local :: { src :: String;    [name :: String]    };
  }
  ```

  # Arguments

  store
  : Either a path literal (the Nix store root of the project) or an
    attribute set whose `src` key is a path literal and whose remaining
    keys are paths to classify and track. Defaults to `paths.store`.

  local
  : Either a string (the local checkout root) or an attribute set whose
    `src` key is that string and whose remaining keys are extra host paths
    (e.g. `pictures`, `downloads`) to classify and track. If omitted,
    `toString store.src` is used as the local root. Defaults to
    `paths.local`.

  meta
  : Resolution bookkeeping, kept separate from `local` so it can never leak
    into the output as a path entry. `meta.usedKey`, if given, names which
    key of `local` was the actual source of `src`, so it can be excluded
    from the extras without blacklisting `dots`/`home` by name.

  # Dependencies

  Builtins
  : `isAttrs`, `isPath`, `isString`, `mapAttrs`, `path`, `removeAttrs`,
    `stringLength`, `substring`, `toString`

  attrsets
  : `filterAttrs`, `mapAttrs`

  strings
  : `hasPrefix`

  # Examples
  ```nix
  # Minimal -- derive everything from a single store path
  mkPaths { store.src = ./.; }

  # Host-defined absolute extras -- local-only, no store counterpart
  mkPaths {
    store = { src = ./.; libraries = ./libraries; };
    local = {
      src       = "/etc/nixos";
      pictures  = "/home/user/Pictures";
      downloads = "/home/user/Downloads";
    };
  }
  # => {
  #   store = { src = /nix/store/...-source; libraries = /nix/store/...-source/libraries; };
  #   local = { src = "/etc/nixos"; libraries = "/etc/nixos/libraries";
  #             pictures = "/home/user/Pictures"; downloads = "/home/user/Downloads"; };
  # }

  # `home` used to derive src is excluded from extras; `home` NOT used to
  # derive src survives as a plain absolute extra
  mkPaths {
    store = { src = ./.; };
    local = { home = "/home/user/dots"; };
    meta.usedKey = "home";
  }
  # => { local = { src = "/home/user/dots"; }; ... }   # no stray `home` key

  mkPaths {
    store = { src = ./.; };
    local = { src = "/home/user/dots"; home = "/home/user"; };
  }
  # => { local = { src = "/home/user/dots"; home = "/home/user"; }; ... }
  ```
  */
  mkPaths = {
    store ? paths.store,
    local ? paths.local or null,
    meta ? {},
  }: let
    _name = "filesystem::mkPaths";

    args = {
      store = store.src or store;
      local =
        if local == null
        then toString args.store
        else if isAttrs local
        then local.src
        or (throw "${_name}: 'local' attrset is missing a 'src' string.")
        else local;
    };

    src = {
      store = path {
        path = args.store;
        name = "source";
      };
      local = toString args.local;
    };

    extrasOf = value:
      if isAttrs value
      then
        removeAttrs value (
          ["src"]
          ++ (
            optionals
            (meta ? usedKey && value ? ${meta.usedKey})
            [meta.usedKey]
          )
          # TODO: Remove after testing
          # ++ (
          #   if meta ? usedKey && value ? ${meta.usedKey}
          #   then [meta.usedKey]
          #   else []
          # )
        )
      else {};

    define = classify {inherit (args) store local;};
    classified =
      mapAttrs (_: define) (extrasOf store)
      // mapAttrs (_: define) (extrasOf local);

    entries = {
      store = filterAttrs (_: kind: kind.root == "store") classified;
      relative = filterAttrs (_: kind: kind.root == "local") classified;
      absolute = filterAttrs (_: kind: kind.root == "absolute") classified;
    };

    rebased = entries.store // entries.relative;
  in
    #TODO: Use debug.withContext
    assert if isAttrs store || isPath store
    then true
    else throw "${_name}: 'store' must be a path literal or an attribute set containing file mappings.";
    assert !isAttrs store
    || (store ? src && isPath store.src)
    || throw "${_name}: 'store' set is missing a valid path for 'src'.";
    assert (local == null)
    || isString local
    || isAttrs local
    || throw "${_name}: 'local' must be a string, an attribute set with 'src', or null."; {
      store =
        {src = src.store;}
        // mapAttrs (_: entry: src.store + entry.stem) rebased;
      local =
        {src = src.local;}
        // mapAttrs (_: entry: src.local + entry.stem) rebased
        // mapAttrs (_: entry: entry.value) entries.absolute;
    };

  /**
  Derive standard per-user folder defaults (Downloads, Pictures, Documents,
  Music, Videos) from a user record's `home` field.

  This is deliberately separate from `mkPaths`, which has no concept of
  "what a user is" -- it only classifies and rebases path-like values
  against known roots. `mkUserPaths` is the policy layer that decides
  what a sensible default folder layout looks like for a given home
  directory; `mkPaths` remains the mechanism layer that doesn't care where
  those defaults came from once they're plain strings. Merge the result
  into `local` before calling `mkPaths`, at the lowest precedence, so any
  global default or host override still wins over the user-derived guess.

  # Type
  ```nix
  mkUserPaths :: { user :: { home :: String; ... }; overrides :: AttrSet? } -> AttrSet
  ```

  # Arguments

  user
  : A user record (e.g. `host.users.primary.value`) with at least a `home`
    string field. Defaults are built as `"${user.home}/<Folder>"`.

  overrides
  : Explicit values to use instead of the computed default for any key,
    merged on top (override wins). Lets a host redefine e.g. `downloads`
    to point somewhere nonstandard without losing the other defaults.

  # Dependencies

  Builtins
  : none beyond string interpolation

  # Examples
  ```nix
  mkUserPaths { user = { home = "/home/craole"; }; }
  # => {
  #   downloads = "/home/craole/Downloads";
  #   pictures  = "/home/craole/Pictures";
  #   documents = "/home/craole/Documents";
  #   music     = "/home/craole/Music";
  #   videos    = "/home/craole/Videos";
  # }

  mkUserPaths {
    user = { home = "/home/craole"; };
    overrides.downloads = "/mnt/data/Downloads";
  }
  # => { downloads = "/mnt/data/Downloads"; pictures = "/home/craole/Pictures"; ... }
  ```
  */
  mkUserPaths = {
    user,
    overrides ? {},
  }: let
    _name = "filesystem::mkUserPaths";
    home =
      user.home
      or (throw "${_name}: 'user' is missing a 'home' string.");
    defaults = {
      downloads = "${home}/Downloads";
      pictures = "${home}/Pictures";
      projects = "${home}/Projects";
      documents = "${home}/Documents";
      music = "${home}/Music";
      videos = "${home}/Videos";
    };
  in
    assert isAttrs user
    || throw "${_name}: 'user' must be an attribute set.";
    assert isString home
    || throw "${_name}: 'user.home' must be a string.";
      defaults // overrides;

  entrypoints.nix = let
    ext = "nix";
    candidates = map (name: "${name}.${ext}") [
      "default"
      "shell"
      "flake"
      "configuration"
      "_"
    ];
    primary = head candidates;
  in {inherit ext candidates primary;};
  entrypoint = entrypoints.nix.primary;

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
    else filter (x: x != "") (split' "/" clean);

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
