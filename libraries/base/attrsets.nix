{
  strings,
  lists,
  ...
}: let
  exports = {
    scoped = {
      inherit
        # as
        asIf
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
        ;
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
      namesOf = attrNames;
      orEmptyNamed = orEmpty';
      valuesOf = attrValues;
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
      defaultOrAllAttrs = preferDefault;
      defaultOrAllValues = preferDefaultValues;
      asAttrs = as;
      asAttrsIf = asIf;
      filterAttrs = select;
      findFirstAttr = firstOf;
      getAttrs = gets;
      getAttrsSafe = gets;
      inheritAttr = orEmpty';
      inspectAttrs = inspect;
      orEmptyAttrs = orEmpty;
      recursiveUpdate = merge;
      recursiveAttrs = merge;
      removeAttrPaths = removePaths;
      removeAttrPath = removePath;
    };
  };

  inherit
    (builtins)
    attrNames
    attrValues
    concatMap
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
  inherit (lists) unique;

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
                (concat ".")
                (concatMap prefixes (permutations entry.scopes))
            );
        in
          concatMap (
            scope:
              map (
                item:
                  split "." (
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

  #TODO: Move to custom.types
  /**
  Coerce a value into an attrset.

  - Attrsets are returned unchanged
  - Strings become `{ ${value} = true; }`
  - Lists become an attrset of boolean flags keyed by list entries

  # Type
  ```nix
  attrsets.as :: { ... } | String | [ String ] -> { ... }
  ```

  # Dependencies
  None

  # Arguments
  value
  : The value to coerce.

  # Examples
  > attrsets.as { a = 1; }
  => { a = 1; }

  > attrsets.as "debug"
  => { debug = true; }

  > attrsets.as [ "debug" "types" ]
  => { debug = true; types = true; }
  */
  as = value: let
    _name = "attrsets.as";
    _args = {
      inherit value;
      type = typeOf value;
    };
  in
    if isAttrs value
    then value
    else if isString value
    then {${value} = true;}
    else if isList value
    then
      listToAttrs (
        map
        (name: {
          inherit name;
          value = true;
        })
        value
      )
    else throw "${_name}: Unsupported type: ${_args.type}";

  /**
  Conditionally coerce a value into an attrset.

  Returns `as value` when `predicate` is true, otherwise `{}`.

  # Type

  ```nix
  asIf :: Bool -> ({ ... } | String | [ String ]) -> { ... }
  ```

  # Dependencies

  - attrsets.as

  # Arguments

  predicate
  : Whether coercion should happen.

  value
  : The value to coerce when enabled.

  # Examples

  ```nix
  asIf true "flake"
  # => { flake = true; }

  asIf false "flake"
  # => {}
  ```
  */
  asIf = predicate: value:
    if predicate
    then as value
    else {};

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
  select = predicate: set:
    listToAttrs (
      map
      (name: {
        inherit name;
        value = set.${name};
      })
      (
        filter
        (name: predicate name set.${name})
        (attrNames set)
      )
    );

  /**
  Select a specific list of attributes from an attrset.

  Returns a new attrset containing only the keys specified in the names list.
  Note that this function will throw an evaluation error if any of the specified
  names do not exist in the source attrset.

  # Type
  ```nix
  gets :: [String] -> { ${String} :: a; } -> { ${String} :: a; }
  ```
  # Dependencies
  None

  # Arguments
  names
  : A list of attribute names (strings) to extract.

  attrs
  : The source attrset to extract values from.

  #Examples
  ```nix
  gets [ "a" "c" ] { a = 1; b = 2; c = 3; }
  # => { a = 1; c = 3; }

  gets [ "x" ] { a = 1; }
  # => error: attribute 'x' missing
  ```
  */
  gets = names: attrs:
    listToAttrs (
      map (name: {
        inherit name;
        value = attrs.${name} or {};
      })
      names
    );

  /**
  Safely select a specific list of attributes from an attrset.

  Returns a new attrset containing only the keys specified in the names list
  that actually exist in the source attrset. Missing keys are gracefully ignored.

  # Type
  ```nix
  gets' :: [String] -> { ${String} :: a; } -> { ${String} :: a; }
  ```

  # Dependencies
  None

  # Arguments
  names
  : A list of attribute names (strings) to look for.

  attrs
  : The source attrset to filter against.

  # Examples
  ```nix
  gets' [ "a" "x" ] { a = 1; b = 2; }
  # => { a = 1; }
  ```
  */
  gets' = names: attrs:
    intersectAttrs
    (listToAttrs (map (name: {
        inherit name;
        value = null;
      })
      names))
    attrs;

  /**
  Recursively inspect an attrset or list to a bounded depth.

  Functions and paths are rendered as placeholders to keep inspection safe
  and REPL-friendly.

  # Type

  ```nix
  inspect :: Int -> a -> a
  ```

  # Dependencies

  - debug.inspect

  # Arguments

  level
  : Maximum inspection depth.

  value
  : The value to inspect.

  # Examples

  ```nix
  inspect 1 { a.b = 1; }
  # => { a = "..."; }
  ```
  */
  inspect = level: let
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

  /**
  Recursively merge two attrsets.

  When both sides contain an attrset at the same key, they are merged
  recursively. Otherwise the right-hand value wins.

  # Type

  ```nix
  merge :: AttrSet -> AttrSet -> AttrSet
  ```

  # Dependencies

  - attrsets.merge

  # Arguments

  lhs
  : The base attrset.

  rhs
  : The overriding attrset.

  # Examples

  ```nix
  merge { a.b = 1; } { a.c = 2; }
  # => { a = { b = 1; c = 2; }; }
  ```
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
        (unique (attrNames lhs ++ attrNames rhs)))
    else rhs;

  /**
  Normalize a value to a non-empty attrset.

  Returns the attrset unchanged when `value` is a non-empty attrset.
  Returns `{}` for empty attrsets and non-attrset values.

  # Type

  ```nix
  orEmpty :: a -> { ... }
  ```

  # Dependencies

  - types.isNotEmpty

  # Arguments

  value
  : The value to normalize.

  # Examples

  ```nix
  orEmpty { a = 1; }
  # => { a = 1; }

  orEmpty {}
  # => {}

  orEmpty null
  # => {}
  ```
  */
  orEmpty = value:
    if isAttrs value && value != {}
    then value
    else {};

  /**
  Inherit a named attribute from a source attrset when it exists.

  Supports two call forms:
  - Curried: `orEmpty' name set`
  - Attrset: `orEmpty' { name = ...; set = ...; }`

  # Type

  ```nix
  orEmpty' :: String -> { ... } -> { ... }
  orEmpty' :: { name :: String; set :: { ... }; ... } -> { ... }
  ```

  # Dependencies

  None

  # Arguments

  name
  : The attribute name to inherit.

  set
  : The source attrset.

  # Examples

  ```nix
  orEmpty' "flake" { flake = { a = 1; }; }
  # => { flake = { a = 1; }; }

  orEmpty' "flake" {}
  # => {}
  ```
  */
  orEmpty' = nameOrArgs:
    if isAttrs nameOrArgs
    then let
      name = nameOrArgs.name or null;
      set = nameOrArgs.set or null;
    in
      if name == null || set == null
      then throw "attrsets.orEmpty':= expected { name, set; }"
      else if hasAttr name set
      then {${name} = getAttr name set;}
      else {}
    else
      set:
        if hasAttr nameOrArgs set
        then {${nameOrArgs} = getAttr nameOrArgs set;}
        else {};

  /**
  Pick the first value from an attrset.

  Returns `null` when the attrset is empty.

  # Type

  ```nix
  firstOf :: AttrSet -> a | null
  ```

  # Dependencies

  None

  # Arguments

  attrs
  : The attrset to inspect.

  # Examples

  ```nix
  firstOf {}
  # => null

  firstOf { a = 1; }
  # => 1
  ```
  */
  firstOf = attrs:
    if attrs == {}
    then null
    else head (attrValues attrs);

  /**
  Prefer a module set's `default` entry when present.

  If `modules.default` exists, returns a singleton list containing only that
  module. Otherwise returns all attribute values of the module set.

  # Type

  ```nix
  preferDefault :: AttrSet -> List
  ```

  # Dependencies
  None
  */
  preferDefault = set:
    if isAttrs set
    then set.default or set
    else {};

  preferDefaultValues = set:
    if isAttrs set
    then
      if set ? default
      then [set.default]
      else attrValues set
    else [];
in
  exports
