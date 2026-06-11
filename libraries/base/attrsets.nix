let
  exports = {
    scoped = {
      inherit
        as
        asIf
        filter
        firstOf
        fromList
        get
        gets
        gets'
        has
        inspect
        is
        merge
        maps
        namesOf
        orEmpty
        orEmpty'
        valuesOf
        ;
      select = filter;
      getFirst = firstOf;
      orEmptyNamed = orEmpty';
      inherit (builtins) isAttrs;
    };

    global = {
      asAttrs = as;
      asAttrsIf = asIf;
      filterAttrs = filter;
      findFirstAttr = firstOf;
      getAttrs = gets;
      getAttrsSafe = gets;
      inheritAttr = orEmpty';
      inspectAttrs = inspect;
      orEmptyAttrs = orEmpty;
      recursiveUpdate = merge;
    };
  };

  inherit ((import ./types.nix).scoped) isNotEmpty;
  inherit (builtins) head isFunction isList isString typeOf;
  namesOf = builtins.attrNames;
  valuesOf = builtins.attrValues;
  get = builtins.getAttr;
  has = builtins.hasAttr;
  is = builtins.isAttrs;
  fromList = builtins.listToAttrs;
  intersect = builtins.intersectAttrs;
  maps = builtins.mapAttrs;

  /**
  Coerce a value into an attrset.

  ```nix
  - Attrsets are returned unchanged
  - Strings become `{ ${value} = true; }`
  - Lists become an attrset of boolean flags keyed by list entries
  ```

  # Type

  ```nix
  as :: { ... } | String | [ String ] -> { ... }
  ```

  # Dependencies

  None

  # Arguments

  value
  : The value to coerce.

  # Examples

  ```nix
  as { a = 1; }
  # => { a = 1; }

  as "debug"
  # => { debug = true; }

  as [ "debug" "types" ]
  # => { debug = true; types = true; }
  ```
  */
  as = value: let
    type = typeOf value;
  in
    if is value
    then value
    else if isString value
    then {${value} = true;}
    else if isList value
    then
      fromList (
        map
        (name: {
          inherit name;
          value = true;
        })
        value
      )
    else throw "attrsets.as:= unsupported type: ${type}";

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
  filter :: (String -> a -> Bool) -> { ${String} :: a; } -> { ${String} :: a; }
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
  filter (_: value: value != null) { a = 1; b = null; }
  # => { a = 1; }

  filter (name: _: name == "a") { a = 1; b = 2; }
  # => { a = 1; }
  ```
  */
  filter = predicate: set:
    fromList (
      map
      (name: {
        inherit name;
        value = set.${name};
      })
      (
        builtins.filter
        (name: predicate name set.${name})
        (namesOf set)
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
    fromList (
      map (name: {
        inherit name;
        value = attrs.${name};
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
    intersect
    (fromList (map (name: {
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
      else if is value
      then maps (_: fn (depth - 1)) value
      else if type == "path"
      then "<path>"
      else value;
  in
    fn level;

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
    if is value && isNotEmpty value
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
    if is nameOrArgs
    then let
      name = nameOrArgs.name or null;
      set = nameOrArgs.set or null;
    in
      if name == null || set == null
      then throw "attrsets.orEmpty':= expected { name, set; }"
      else if has name set
      then {${name} = get name set;}
      else {}
    else
      set:
        if has nameOrArgs set
        then {${nameOrArgs} = get nameOrArgs set;}
        else {};

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
    if is lhs && is rhs
    then
      fromList (
        map
        (key: {
          name = key;
          value =
            if lhs ? ${key} && rhs ? ${key}
            then merge lhs.${key} rhs.${key}
            else rhs.${key} or lhs.${key};
        })
        (namesOf (lhs // rhs))
      )
    else rhs;

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
    else head (valuesOf attrs);
in
  exports
