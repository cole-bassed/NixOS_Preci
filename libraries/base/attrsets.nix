{
  strings,
  trivial,
  lists,
  ...
}: let
  exports = {
    scoped = {
      inherit
        as
        asEnabled
        asIf
        extractArgs
        firstOf
        gets
        gets'
        inspect
        merge
        normalizePaths
        orEmpty
        orEmpty'
        removePath
        removePaths
        preferDefaultValues
        preferDefault
        select
        valuesOf
        namesOf
        foldMerge
        ;
      optionalAttrs = asIf;
      defaultOrAll = preferDefault;
      defaultOrAllValues = preferDefaultValues;
      filter = select;
      fromList = listToAttrs;
      get = getAttr;
      getFirst = firstOf;
      has = hasAttr;
      head = firstOf;
      intersect = intersectAttrs;
      is = isAttrs;
      maps = mapAttrs;
      orEmptyNamed = orEmpty';
    };

    global = {
      inherit
        (builtins)
        attrNames
        attrValues
        getAttr
        hasAttr
        listToAttrs
        isAttrs
        intersectAttrs
        mapAttrs
        zipAttrsWith
        ;
      inherit extractArgs;
      defaultOrAllAttrs = preferDefault;
      defaultOrAllValues = preferDefaultValues;
      asAttrs = as;
      asAttrsEnabled = asEnabled;
      asAttrsIf = asIf;
      filterAttrs = select;
      findFirstAttr = firstOf;
      getAttrs = gets;
      getAttrsSafe = gets;
      inheritAttr = orEmpty';
      inspectAttrs = inspect;
      orEmptyAttrs = orEmpty;
      recursiveUpdate = merge;
      recursiveUpdateFold = foldMerge;
      recursiveAttrs = merge;
      removeAttrPaths = removePaths;
      removeAttrPath = removePath;
    };
  };

  inherit
    (builtins)
    all
    attrNames
    attrValues
    concatMap
    elem
    filter
    foldl'
    getAttr
    hasAttr
    head
    isAttrs
    isFunction
    intersectAttrs
    isList
    isString
    listToAttrs
    mapAttrs
    tail
    typeOf
    ;

  inherit (strings) concat split;
  inherit (lists) lastOf unique';
  inherit (trivial) makeHybrid readHybrid;

  /**
  Normalize raw path inputs into consistent lists of split string segments.
  Accepts flat strings, lists of segments, or a matrix set containing `scopes` and `items`.

  # Type
  ```nix
  normalizePaths :: [ String | [ String ] | AttrSet ] -> [ [ String ] ]
  normalizePaths :: { paths :: [ ... ]; } -> [ [ String ] ]
  ```

  # Dependencies
  - builtins.concatMap
  - builtins.filter
  - builtins.head
  - builtins.isAttrs
  - builtins.isList
  - builtins.map
  - builtins.tail
  - strings.concat
  - strings.split

  # Arguments
  args
  : Either a raw list of path entries, or an attribute set `{ paths = [ ... ]; }`
  wrapping that list. Each entry in the list may be:
    - a flat dot-separated string (e.g. `"lib.lists.fold"`),
    - a pre-segmented list of strings (e.g. `[ "lib" "lists" "fold" ]`), or
    - a matrix set `{ scopes; items; root ?; exact ?; }` that expands to every
      combination of `scopes` and `items`.

  Matrix set options:
    - `root`:  boolean (default: `true`). Unconditionally checks the root scope.
    - `exact`: boolean (default: `false`). If `true`, disables full permutation
      generation and treats the provided `scopes` as literal, exact paths.

  # Examples
  - __Flat string entries__

  > normalizePaths [ "a.b.c" ]
  => [ [ "a" "b" "c" ] ]

  - __Pre-segmented list entries__

  > normalizePaths [ [ "a" "b" ] ]
  => [ [ "a" "b" ] ]

  - __Matrix set, exact scopes__

  > normalizePaths [ { scopes = ["lib.lists"]; items = ["fold"]; exact = true; } ]
  => [ [ "fold" ] [ "lib" "lists" "fold" ] ]

  - __Attribute-set wrapper form__

  > normalizePaths { paths = [ "a.b" ]; }
  => [ [ "a" "b" ] ]
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
                (concat ".")
                (concatMap prefixes (permutations entry.scopes))
            );
        in
          concatMap (
            scope:
              map (
                item:
                  split "."
                  (
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
        else [(split "." entry)]
    ) (
      if isAttrs args && args ? paths
      then args.paths
      else args
    );

  /**
  Recursively traverses an attribute set to remove a single pre-segmented path.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (set, then list) — the
  curried order matches the native `removeAttrs` input style: `(set -> path)`.

  # Type
  ```nix
  removePath :: AttrSet -> { ... }
  removePath :: { ... } -> [ String ] -> { ... }
  ```

  # Dependencies
  - builtins.head
  - builtins.isAttrs
  - builtins.removeAttrs
  - builtins.tail
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set `{ set, list }`, or the source attribute
  set for curried positional invocation.

  set
  : The attribute set to remove a path from.

  list
  : The pre-segmented path (a list of string keys) to remove, innermost key last.

  # Examples
  - __Explicit Attribute Set Configuration__

  > removePath { set = { lib.lists.fold = 1; }; list = [ "lib" "lists" "fold" ]; }
  => { lib = { lists = {}; }; }

  - __Curried Positional (Set then List)__

  > removePath { lib.lists.fold = 1; } [ "lib" "lists" "fold" ]
  => { lib = { lists = {}; }; }

  - __Missing intermediate keys are safe no-ops__

  > removePath { a = 1; } [ "b" "c" ]
  => { a = 1; }

  - __Partial application__

  > removeFoldPath = removePath { lib.lists.fold = 1; };
  > removeFoldPath [ "lib" "lists" "fold" ]
  => { lib = { lists = {}; }; }
  */
  removePath = arg: let
    positional = ["set" "list"];
    primary = lastOf positional;

    exec = set: list:
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
        then set // {${path.initial} = exec set.${path.initial} path.remaining;}
        else set;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        exec args.set args.list
    );
  in
    function arg;

  /**
  Remove nested attributes from a set using a list of dot-separated path
  strings or lists of strings. Safe against missing intermediate keys.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (set, then paths) — the
  curried order matches the native `removeAttrs` input style.

  # Type
  ```nix
  removePaths :: AttrSet -> { ... }
  removePaths :: { ... } -> [ String | [ String ] | AttrSet ] -> { ... }
  ```

  # Dependencies
  - builtins.foldl'
  - attrsets.normalizePaths
  - attrsets.removePath

  # Arguments
  arg
  : A configuration attribute set `{ set, paths }`, or the source attribute
  set for curried positional invocation.

  set
  : The attribute set to remove paths from.

  paths
  : A list of path entries, in any form accepted by `normalizePaths`
  (dot-separated strings, pre-segmented lists, or matrix sets).

  # Examples
  - __Explicit Attribute Set Configuration__

  > removePaths { set = { lists.fold = 1; }; paths = [ "lists.fold" ]; }
  => { lists = {}; }

  - __Curried Positional (Set then Paths, matches `removeAttrs`)__

  > removePaths { lists.fold = 1; } [ "lists.fold" ]
  => { lists = {}; }

  - __Multiple paths in one call__

  > removePaths { a.b = 1; c.d = 2; } [ "a.b" "c.d" ]
  => { a = {}; c = {}; }

  - __Partial application__

  > removeFromLib = removePaths { lists.fold = 1; unique = 2; };
  > removeFromLib [ "lists.fold" ]
  => { lists = {}; unique = 2; }
  */
  removePaths = arg: let
    positional = ["set" "paths"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        foldl' removePath args.set (normalizePaths args.paths)
    );
  in
    function arg;

  /**
  Coerce a value into an attrset.

  - Attrsets are returned unchanged
  - Strings become `{ ${value} = {}; }`
  - Lists become an attrset of empty sets keyed by list entries
  - Null becomes an empty attrset `{}`

  # Type
  ```nix
  as :: { ... } | String | [ String ] | Null -> { ... }
  ```

  # Dependencies
  None

  # Arguments
  value
  : The value to coerce.

  # Examples
  > as { a = 1; }
  => { a = 1; }

  > as "debug"
  => { debug = {}; }

  > as [ "debug" "types" ]
  => { debug = {}; types = {}; }

  > as null
  => {}
  */
  as = value: let
    _name = "attrsets.as";
  in
    if isAttrs value
    then value
    else if isString value
    then {${value} = {};}
    else if isList value
    then
      listToAttrs (map (name: {
          inherit name;
          value = {};
        })
        value)
    else if value == null
    then {}
    else throw "${_name}: Unsupported type: ${typeOf value}";

  /**
  Coerce a value into an attrset of boolean-enabled flags.

  - Attrsets are returned unchanged
  - Strings become `{ ${value} = true; }`
  - Lists become an attrset of boolean flags keyed by list entries

  # Type
  ```nix
  asEnabled :: { ... } | String | [ String ] -> { ... }
  ```

  # Dependencies
  - attrsets.as
  - builtins.mapAttrs

  # Arguments
  value
  : The value to coerce.

  # Examples
  > asEnabled { a = 1; }
  => { a = 1; }

  > asEnabled "debug"
  => { debug = true; }

  > asEnabled [ "debug" "types" ]
  => { debug = true; types = true; }
  */
  asEnabled = value: mapAttrs (_name: _v: true) (as value);

  /**
  Conditionally coerce a value into an attrset.

  Returns `as value` when `predicate` is true, otherwise `{}`.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (predicate, then value).

  # Type
  ```nix
  asIf :: AttrSet -> { ... }
  asIf :: Bool -> ({ ... } | String | [ String ]) -> { ... }
  ```

  # Dependencies
  - attrsets.as
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set `{ predicate, value }`, or the predicate
  boolean for curried positional invocation.

  predicate
  : Whether coercion should happen.

  value
  : The value to coerce when enabled.

  # Examples
  - __Explicit Attribute Set Configuration__

  > asIf { predicate = true; value = "flake"; }
  => { flake = {}; }

  > asIf { predicate = false; value = "flake"; }
  => {}

  - __Curried Positional (Predicate then Value)__

  > asIf true "flake"
  => { flake = {}; }

  > asIf false "flake"
  => {}

  - __Partial application__

  > enabledOnly = asIf true;
  > enabledOnly [ "flake" "devShell" ]
  => { flake = {}; devShell = {}; }
  */
  asIf = arg: let
    positional = ["predicate" "value"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        if args.predicate
        then as args.value
        else {}
    );
  in
    function arg;

  /**
  Filter an attrset by attribute name and value.

  Returns a new attrset containing only the attributes for which
  `predicate name value` returns true.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (predicate, then set).

  # Type
  ```nix
  select :: AttrSet -> { ${String} :: a; }
  select :: (String -> a -> Bool) -> { ${String} :: a; } -> { ${String} :: a; }
  ```

  # Dependencies
  - builtins.attrNames
  - builtins.filter
  - builtins.listToAttrs
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set `{ predicate, set }`, or the predicate
  function for curried positional invocation.

  predicate
  : A function taking an attribute name and value, returning a bool.

  set
  : The attrset to filter.

  # Examples
  - __Explicit Attribute Set Configuration__

  > select { predicate = _: value: value != null; set = { a = 1; b = null; }; }
  => { a = 1; }

  - __Curried Positional (Predicate then Set)__

  > select (_: value: value != null) { a = 1; b = null; }
  => { a = 1; }

  > select (name: _: name == "a") { a = 1; b = 2; }
  => { a = 1; }

  - __Partial application__

  > dropNulls = select (_: value: value != null);
  > dropNulls { a = 1; b = null; c = 3; }
  => { a = 1; c = 3; }
  */
  select = arg: let
    positional = ["predicate" "set"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        listToAttrs (
          map
          (name: {
            inherit name;
            value = args.set.${name};
          })
          (
            filter
            (name: args.predicate name args.set.${name})
            (attrNames args.set)
          )
        )
    );
  in
    function arg;

  /**
  Select a specific list of attributes from an attrset.

  Returns a new attrset containing only the keys specified in the names list.
  Note that this function will throw an evaluation error if any of the specified
  names do not exist in the source attrset.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (names, then attrs).

  # Type
  ```nix
  gets :: AttrSet -> { ${String} :: a; }
  gets :: [ String ] -> { ${String} :: a; } -> { ${String} :: a; }
  ```

  # Dependencies
  - builtins.listToAttrs
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set `{ names, attrs }`, or the list of names
  for curried positional invocation.

  names
  : A list of attribute names (strings) to extract.

  attrs
  : The source attrset to extract values from.

  # Examples
  - __Explicit Attribute Set Configuration__

  > gets { names = [ "a" "c" ]; attrs = { a = 1; b = 2; c = 3; }; }
  => { a = 1; c = 3; }

  - __Curried Positional (Names then Attrs)__

  > gets [ "a" "c" ] { a = 1; b = 2; c = 3; }
  => { a = 1; c = 3; }

  - __Missing names default to `{}` rather than throwing, per the `or {}`
  guard below — see `gets'` for a variant that omits missing keys entirely__

  > gets [ "x" ] { a = 1; }
  => { x = {}; }

  - __Partial application__

  > pickAC = gets [ "a" "c" ];
  > pickAC { a = 1; b = 2; c = 3; }
  => { a = 1; c = 3; }
  */
  gets = arg: let
    positional = ["names" "attrs"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        listToAttrs (
          map (name: {
            inherit name;
            value = args.attrs.${name} or {};
          })
          args.names
        )
    );
  in
    function arg;

  /**
  Safely select a specific list of attributes from an attrset.

  Returns a new attrset containing only the keys specified in the names list
  that actually exist in the source attrset. Missing keys are gracefully ignored.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (names, then attrs).

  # Type
  ```nix
  gets' :: AttrSet -> { ${String} :: a; }
  gets' :: [ String ] -> { ${String} :: a; } -> { ${String} :: a; }
  ```

  # Dependencies
  - builtins.intersectAttrs
  - builtins.listToAttrs
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set `{ names, attrs }`, or the list of names
  for curried positional invocation.

  names
  : A list of attribute names (strings) to look for.

  attrs
  : The source attrset to filter against.

  # Examples
  - __Explicit Attribute Set Configuration__

  > gets' { names = [ "a" "x" ]; attrs = { a = 1; b = 2; }; }
  => { a = 1; }

  - __Curried Positional (Names then Attrs)__

  > gets' [ "a" "x" ] { a = 1; b = 2; }
  => { a = 1; }

  - __Partial application__

  > pickIfPresent = gets' [ "a" "x" ];
  > pickIfPresent { a = 1; b = 2; }
  => { a = 1; }

  > pickIfPresent { x = 9; }
  => { x = 9; }
  */
  gets' = arg: let
    positional = ["names" "attrs"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        intersectAttrs
        (listToAttrs (map (name: {
            inherit name;
            value = null;
          })
          args.names))
        args.attrs
    );
  in
    function arg;

  /**
  Recursively inspect an attrset or list to a bounded depth.

  Functions and paths are rendered as placeholders to keep inspection safe
  and REPL-friendly.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (level, then value). The
  curried single-argument form (`inspect 1`) still yields a partial function
  awaiting `value`, exactly as before hybridization.

  # Type
  ```nix
  inspect :: AttrSet -> a
  inspect :: Int -> a -> a
  ```

  # Dependencies
  - builtins.isAttrs
  - builtins.isFunction
  - builtins.isList
  - builtins.mapAttrs
  - builtins.typeOf
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set `{ level, value }`, or the maximum
  inspection depth for curried positional invocation.

  level
  : Maximum inspection depth.

  value
  : The value to inspect.

  # Examples
  - __Explicit Attribute Set Configuration__

  > inspect { level = 1; value = { a.b = 1; }; }
  => { a = "..."; }

  - __Curried Positional (Level then Value)__

  > inspect 1 { a.b = 1; }
  => { a = "..."; }

  - __Partial application__

  > inspectShallow = inspect 1;
  > inspectShallow { a.b = 1; c = 2; }
  => { a = "..."; c = 2; }

  - __Functions and paths are rendered as placeholders__

  > inspect 2 { fn = x: x; }
  => { fn = "<function>"; }
  */
  inspect = arg: let
    positional = ["level" "value"];
    primary = lastOf positional;

    exec = level: let
      fn = depth: value: let
        type = typeOf value;
      in
        if depth <= 0
        then "..."
        else if isFunction value
        then "<function>"
        else if isList value
        then map (fn (depth - 1)) value
        else if isAttrs value
        then mapAttrs (_: fn (depth - 1)) value
        else if type == "path"
        then "<path>"
        else value;
    in
      fn level;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        exec args.level args.value
    );
  in
    function arg;

  /**
  Recursively merge two attrsets.

  When both sides contain an attrset at the same key, they are merged
  recursively. Otherwise the right-hand value wins.

  Kept as a plain curried function (not hybridized) because `merge` is
  self-recursive on nested values — hybridizing the entry point would not
  simplify the recursive call sites and adds unnecessary dispatch overhead
  to every nested merge step.

  # Type
  ```nix
  merge :: AttrSet -> AttrSet -> AttrSet
  ```

  # Dependencies
  - attrsets.merge (self, recursive)
  - builtins.listToAttrs
  - lists.unique

  # Arguments
  lhs
  : The base attrset.

  rhs
  : The overriding attrset.

  # Examples
  > merge { a.b = 1; } { a.c = 2; }
  => { a = { b = 1; c = 2; }; }

  > merge { a = 1; } { a = 2; }
  => { a = 2; }

  - __Partial application__

  > mergeIntoBase = merge { a.b = 1; };
  > mergeIntoBase { a.c = 2; }
  => { a = { b = 1; c = 2; }; }
  */
  merge = lhs: rhs:
    if isAttrs lhs && isAttrs rhs
    then
      listToAttrs (map
        (name: {
          inherit name;
          value =
            if lhs ? ${name} && rhs ? ${name}
            then merge lhs.${name} rhs.${name}
            else rhs.${name} or lhs.${name};
        })
        (unique' (attrNames lhs ++ attrNames rhs)))
    else rhs;

  /**
  Recursively fold a list of attrsets into one, via `merge`.

  Non-attrset entries in the list are silently dropped before folding.

  # Type
  ```nix
  foldMerge :: [ AttrSet ] -> AttrSet
  ```

  # Dependencies
  - attrsets.merge
  - builtins.filter
  - builtins.foldl'
  - builtins.isAttrs

  # Arguments
  list
  : A list of attrsets (or mixed values) to fold together, left to right.

  # Examples
  > foldMerge [ { a = 1; } { b = 2; } ]
  => { a = 1; b = 2; }

  > foldMerge [ { a.x = 1; } { a.y = 2; } ]
  => { a = { x = 1; y = 2; }; }

  - __Non-attrset entries are dropped__

  > foldMerge [ { a = 1; } "ignored" { b = 2; } ]
  => { a = 1; b = 2; }

  > foldMerge []
  => {}
  */
  foldMerge = list:
    foldl' merge {} (filter isAttrs list);

  /**
  Normalize a value to a non-empty attrset.

  Returns the attrset unchanged when `value` is a non-empty attrset.
  Returns `{}` for empty attrsets and non-attrset values.

  # Type
  ```nix
  orEmpty :: a -> { ... }
  ```

  # Dependencies
  - builtins.isAttrs

  # Arguments
  value
  : The value to normalize.

  # Examples
  > orEmpty { a = 1; }
  => { a = 1; }

  > orEmpty {}
  => {}

  > orEmpty null
  => {}

  > orEmpty "hello"
  => {}
  */
  orEmpty = value:
    if isAttrs value && value != {}
    then value
    else {};

  /**
  Inherit a named attribute from a source attrset when it exists.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (name, then set).

  # Type
  ```nix
  orEmpty' :: AttrSet -> { ... }
  orEmpty' :: String -> { ... } -> { ... }
  ```

  # Dependencies
  - builtins.getAttr
  - builtins.hasAttr
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set `{ name, set }`, or the attribute name
  for curried positional invocation.

  name
  : The attribute name to inherit.

  set
  : The source attrset.

  # Examples
  - __Explicit Attribute Set Configuration__

  > orEmpty' { name = "flake"; set = { flake = { a = 1; }; }; }
  => { flake = { a = 1; }; }

  - __Curried Positional (Name then Set)__

  > orEmpty' "flake" { flake = { a = 1; }; }
  => { flake = { a = 1; }; }

  > orEmpty' "flake" {}
  => {}

  - __Partial application__

  > inheritFlake = orEmpty' "flake";
  > inheritFlake { flake = { a = 1; }; other = 2; }
  => { flake = { a = 1; }; }
  */
  orEmpty' = arg: let
    positional = ["name" "set"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        if hasAttr args.name args.set
        then {${args.name} = getAttr args.name args.set;}
        else {}
    );
  in
    function arg;

  /**
  Pick the first value from an attrset.

  Returns `null` when the attrset is empty.

  # Type
  ```nix
  firstOf :: AttrSet -> a | null
  ```

  # Dependencies
  - builtins.attrValues
  - builtins.head

  # Arguments
  attrs
  : The attrset to inspect.

  # Examples
  > firstOf {}
  => null

  > firstOf { a = 1; }
  => 1

  > firstOf { b = 2; a = 1; }
  => 2
  */
  firstOf = attrs:
    if attrs == {}
    then null
    else head (attrValues attrs);

  /**
  Prefer a module set's `default` entry when present.

  If `set.default` exists, returns it directly. Otherwise returns the whole
  set unchanged.

  # Type
  ```nix
  preferDefault :: AttrSet -> a
  ```

  # Dependencies
  None

  # Arguments
  set
  : The attrset to inspect.

  # Examples
  > preferDefault { default = { a = 1; }; extra = 2; }
  => { a = 1; }

  > preferDefault { a = 1; b = 2; }
  => { a = 1; b = 2; }

  > preferDefault "not-a-set"
  => {}
  */
  preferDefault = set:
    if isAttrs set
    then set.default or set
    else {};

  /**
  Prefer a module set's `default` entry when present, as a singleton list.

  If `set.default` exists, returns `[ set.default ]`. Otherwise returns
  `builtins.attrValues set`.

  # Type
  ```nix
  preferDefaultValues :: AttrSet -> [ a ]
  ```

  # Dependencies
  - builtins.attrValues
  - builtins.isAttrs

  # Arguments
  set
  : The attrset to inspect.

  # Examples
  > preferDefaultValues { default = { a = 1; }; extra = 2; }
  => [ { a = 1; } ]

  > preferDefaultValues { a = 1; b = 2; }
  => [ 1 2 ]

  > preferDefaultValues "not-a-set"
  => []
  */
  preferDefaultValues = set:
    if isAttrs set
    then
      if set ? default
      then [set.default]
      else attrValues set
    else [];

  /**
  Normalize a value into a list of its "values".

  - Lists are returned unchanged
  - Attrsets become their `attrValues`
  - Strings become a singleton list containing the string
  - Anything else becomes `[]`

  # Type
  ```nix
  valuesOf :: [ a ] | AttrSet | String | a -> [ a ]
  ```

  # Dependencies
  - builtins.attrValues
  - builtins.isAttrs
  - builtins.isList
  - builtins.isString

  # Arguments
  value
  : The value to normalize.

  # Examples
  > valuesOf [ 1 2 3 ]
  => [ 1 2 3 ]

  > valuesOf { a = 1; b = 2; }
  => [ 1 2 ]

  > valuesOf "solo"
  => [ "solo" ]

  > valuesOf null
  => []
  */
  valuesOf = value:
    if isList value
    then value
    else if isAttrs value
    then attrValues value
    else if isString value
    then [value]
    else [];

  /**
  Normalize a value into a list of its attribute names.

  - Attrsets become their `attrNames`
  - Anything else becomes `[]`

  # Type
  ```nix
  namesOf :: AttrSet | a -> [ String ]
  ```

  # Dependencies
  - builtins.attrNames
  - builtins.isAttrs

  # Arguments
  value
  : The value to normalize.

  # Examples
  > namesOf { a = 1; b = 2; }
  => [ "a" "b" ]

  > namesOf [ 1 2 3 ]
  => []

  > namesOf null
  => []
  */
  namesOf = value:
    if isAttrs value
    then attrNames value
    else [];

  /**
  Explode, validate, and apply defaults/fallbacks to a function's arguments.

  > **Deprecated**: this predates `trivial.readHybrid`, which now serves the
  > same purpose across the `lix` library and should be preferred for all
  > new code. `extractArgs` is kept only because some existing call sites
  > still depend on it; do not build new functions on top of it, and prefer
  > migrating existing callers to `trivial.makeHybrid` / `trivial.readHybrid`
  > when touching them. Marked for eventual removal.

  Unlike `readHybrid`, `extractArgs` takes its own payload as a single
  attribute set argument (via `args` or `payload`) rather than being wrapped
  by `makeHybrid` — it has no curried/positional dispatch of its own.

  # Type
  ```nix
  extractArgs :: {
    args ? null;
    payload ? null;
    required ? [ ];
    optional ? allowed;
    defaults ? { };
    allowed ? required ++ (attrNames defaults);
    legacyMapKey ? (head required);
  } -> AttrSet
  ```

  # Dependencies
  - builtins.all
  - builtins.attrNames
  - builtins.elem
  - builtins.hasAttr
  - builtins.head
  - builtins.isAttrs
  - lists.unique

  # Arguments
  args
  : The payload attribute set to validate (either this or `payload` must be given).

  payload
  : Alternate name for the payload attribute set; used when `args` is `null`.

  required
  : A list of attribute names that must be present in the payload.

  optional
  : A list of additional attribute names allowed but not required. Defaults
  to `allowed`.

  defaults
  : An attrset of default values merged under the final result.

  allowed
  : The full list of attribute names permitted in the payload. Defaults to
  `required ++ (attrNames defaults)`.

  legacyMapKey
  : The key used to wrap the raw payload under when it doesn't match the
  expected shape (i.e. the "shorthand" fallback key). Defaults to the first
  entry of `required`.

  # Examples
  - __Well-formed payload passes through with defaults applied__

  > extractArgs { args = { parts = [ "a" "b" ]; }; required = [ "parts" ]; defaults.delim = ""; }
  => { delim = ""; parts = [ "a" "b" ]; }

  - __Malformed / shorthand payload falls back to `legacyMapKey`__

  > extractArgs { args = [ "a" "b" ]; required = [ "parts" ]; defaults.delim = ""; }
  => { delim = ""; parts = [ "a" "b" ]; }

  - __Using `payload` instead of `args`__

  > extractArgs { payload = { parts = [ "x" ]; }; required = [ "parts" ]; }
  => { parts = [ "x" ]; }

  - __Neither `args` nor `payload` given throws__

  > extractArgs { required = [ "parts" ]; }
  => error: extractArgs: no args or payload provided
  */
  extractArgs = {
    args ? null,
    payload ? null,
    required ? [],
    optional ? allowed,
    defaults ? {},
    allowed ? required ++ (attrNames defaults),
    legacyMapKey ? (head required),
  }: let
    value =
      if args != null
      then args
      else if payload != null
      then payload
      else throw "extractArgs: no args or payload provided";

    allAllowed = unique' (allowed ++ optional);

    check =
      (isAttrs value)
      && (all (req: hasAttr req value) required)
      && (all (key: elem key allAllowed) (attrNames value));
  in
    if check
    then defaults // value
    else defaults // {"${legacyMapKey}" = value;};
in
  exports
