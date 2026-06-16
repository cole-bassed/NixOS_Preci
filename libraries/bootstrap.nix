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
    isString
    listToAttrs
    match
    split
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

    prefixed = map (s: s // {prefix = prefix ++ (s.prefix or []);}) (concatMap flattenSpec specs);

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
  inherit mkLibs recursiveSelf recursiveAttrs removePaths;
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
