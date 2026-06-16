let
  inherit
    (builtins)
    attrNames
    concatMap
    concatStringsSep
    filter
    foldl'
    head
    isAttrs
    isList
    isPath
    path
    mapAttrs
    isString
    listToAttrs
    match
    split
    stringLength
    substring
    tail
    ;

  recursiveSelf = fn: let self = fn self; in self;

  recursiveAttrs = lhs: rhs:
    if isAttrs lhs && isAttrs rhs
    then
      listToAttrs (map (key: {
        name = key;
        value =
          if lhs ? ${key} && rhs ? ${key}
          then recursiveAttrs lhs.${key} rhs.${key}
          else rhs.${key} or lhs.${key};
      }) (attrNames (lhs // rhs)))
    else rhs;

  stem = path: let
    name = baseNameOf (toString path);
    groups = match "^(.*)\\.nix$" name;
  in
    if groups == null
    then name
    else head groups;

  nest = path: value:
    if path == []
    then value
    else {${head path} = nest (tail path) value;};

  asList = value:
    if isList value
    then value
    else if (isPath value || isString value)
    then [value]
    else if isAttrs value
    then attrNames value
    else [value];

  gets = names: attrs:
    listToAttrs (map (name: {
        inherit name;
        value = attrs.${name} or {};
      })
      names);

  /**
  Splits a string by a literal string separator.
  Safe for bootstrap as it only relies on basic builtins.
  */
  splitString = sep: str: let
    # Basic regex escaping for common delimiters like '.' or '-'
    # If your paths only use dots, escaping the dot is the main priority.
    escapedSep =
      if sep == "."
      then "\\."
      else if sep == "*"
      then "\\*"
      else if sep == "+"
      then "\\+"
      else sep;

    rawSplit = split escapedSep str;
  in
    filter isString rawSplit;

  /**
  Normalize raw path inputs into consistent lists of split string segments.
  Accepts flat strings, lists of segments, or a matrix set containing `scopes` and `items`.

  Options for matrix sets:
    - root:  boolean (default: true). Unconditionally checks the root scope.
    - exact: boolean (default: false). If true, disables full permutation generation
             and treats the provided `scopes` as literal, exact paths.

  Example:
    normalizePaths [ { scopes = ["lib.lists"]; items = ["fold"]; exact = true; } ]
    # => [ ["fold"] ["lib" "lists" "fold"] ]
  */
  normalizePaths = args:
    concatMap (
      entry:
        if isAttrs entry && entry ? scopes && entry ? items
        then let
          permutations = list:
            if list == []
            then [[]]
            else
              concatMap (
                element:
                  map (
                    perm: [element] ++ perm
                  ) (permutations (filter (candidate: candidate != element) list))
              )
              list;

          prefixes = list:
            if list == []
            then []
            else
              [[(head list)]]
              ++ map (perm: [(head list)] ++ perm) (prefixes (tail list));

          scopeStrings =
            (
              if (entry.root or true)
              then [""]
              else []
            )
            ++ (
              if (entry.exact or false)
              then entry.scopes
              else
                map
                (concatStringsSep ".")
                (concatMap prefixes (permutations entry.scopes))
            );
        in
          concatMap (
            scope:
              map (
                item:
                  splitString "." (
                    if scope == ""
                    then item
                    else "${scope}.${item}"
                  )
              )
              entry.items
          )
          scopeStrings
        else if isList entry
        then entry
        else [(splitString "." entry)]
    ) (
      if isAttrs args && args ? paths
      then args.paths
      else args
    );

  /**
  Recursively traverses an attribute set to remove a single pre-segmented path.
  Matches the native `removeAttrs` input style: (set -> path).

  Example:
    removePath { lib = { lists = { fold = ...; }; }; } [ "lib" "lists" "fold" ]
  */
  removePath = set: list:
    if !isAttrs set || list == []
    then set
    else let
      path = {
        initial = head list;
        remaining = tail list;
      };
    in
      if path.remaining == []
      then removeAttrs set [path.initial]
      else if set ? ${path.initial}
      then set // {${path.initial} = removePath set.${path.initial} path.remaining;}
      else set;

  /**
  Remove nested attributes from a set using a list of dot-separated path strings
  or lists of strings. Safe against missing intermediate keys.

  Example (AttrSet style):
    removePaths { inherit set; paths = [ "lists.fold" ]; }

  Example (Positional style - matches removeAttrs):
    removePaths set [ "lists.fold" ]
  */
  removePaths = args: let
    exec = set: list: foldl' removePath set (normalizePaths list);
  in
    if isAttrs args && args ? set && args ? paths
    then with args; exec set paths
    else exec args;

  /**
  Filter an attrset by attribute name and value.

  Returns a new attrset containing only the attributes for which
  `predicate name value` returns true.

  # Type

  ```nix
  select :: (String -> a -> Bool) -> { ${String} :: a; } -> { ${String} :: a; }
  ```

  # Dependencies

  None

  # Arguments

  predicate
  : A function taking an attribute name and value.

  set
  : The attrset to filter.

  # Examples

  ```nix
  select (_: value: value != null) { a = 1; b = null; }
  # => { a = 1; }

  select (name: _: name == "a") { a = 1; b = 2; }
  # => { a = 1; }
  ```
  */
  filterAttrs = predicate: set:
    removeAttrs set (
      filter
      (name: !predicate name set.${name})
      (attrNames set)
    );
  # filterAttrs = predicate: set:
  #   listToAttrs (
  #     map
  #     (name: {
  #       inherit name;
  #       value = set.${name};
  #     })
  #     (
  #       filter
  #       (name: predicate name set.${name})
  #       (attrNames set)
  #     )
  #   );

  hasPrefix = prefix: string: let
    prefixLen = stringLength prefix;
  in
    prefixLen
    <= stringLength string
    && substring 0 prefixLen string == prefix;

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
    paths ? {src = ./../.;},
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
        path = root.path;
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
        // mapAttrs (_: value: toString value) absolute
        // mapAttrs (_: value: toString value) localExtras;
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

  mkLib = {
    input,
    output ? [(stem input)],
    args ? {},
  }: let
    imported = import input args;
    scoped = imported.scoped or imported.global or imported;
    global = imported.global or {};
    value = recursiveAttrs scoped global;
  in
    {
      __raw = imported;
      __scoped = scoped;
      __global = global;
      __value = value;
    }
    // (nest (asList output) value);

  mkLibs = {
    specs,
    prefix ? [],
    base ? {},
    seed ? {},
  }: let
    flattenSpec = spec:
      if spec ? specs
      then concatMap (child: flattenSpec (child // {prefix = (spec.prefix or []) ++ (child.prefix or []);})) spec.specs
      else [spec];

    prefixed = map (spec: spec // {prefix = prefix ++ (spec.prefix or []);}) (concatMap flattenSpec specs);

    mkOne = state: {
      input,
      dependencies ? [],
      output ? null,
      prefix ? [],
    }: let
      finalOutput =
        if output == null
        then prefix ++ [(stem input)]
        else prefix ++ asList output;
      args = gets dependencies state.nested;
      module = mkLib {
        inherit input args;
        output = finalOutput;
      };
    in {
      nested = recursiveAttrs state.nested module;
      globals = recursiveAttrs state.globals (module.__global or {});
    };

    result =
      foldl' mkOne {
        nested = recursiveAttrs base seed;
        globals = {};
      }
      prefixed;
  in
    with result; recursiveAttrs nested globals;
in {
  inherit mkLibs recursiveSelf recursiveAttrs removePaths mkPaths;
  attrsets = {
    inherit recursiveAttrs;
    merge = recursiveAttrs;
  };
  config = {
    inherit mkLib mkLibs recursiveSelf;
    fix = recursiveSelf;
  };
  lists = {
    inherit asList foldl' concatMap;
  };
}
