let
  exports = {
    scoped = {
      inherit
        as
        asIf
        filter
        inheritOne
        orEmpty
        update
        findFirst
        ;
    };

    global = {
      asAttrs = as;
      asAttrsIf = asIf;
      filterAttrs = filter;
      inheritAttr = inheritOne;
      orEmptyAttrs = orEmpty;
      recursiveUpdate = update;
      recursiveUpdate' = update;
      pickFirst = findFirst;
      findFirstAttr = findFirst;
    };
  };

  inherit
    (builtins)
    attrNames
    attrValues
    getAttr
    hasAttr
    head
    isAttrs
    isList
    isString
    listToAttrs
    typeOf
    ;

  inherit ((import ./types.nix).scoped) isNotEmpty;

  /**
  Coerce a value into an attrset.

  Supported inputs:
  - Attrsets are returned unchanged
  - Strings become `{ ${value} = true; }`
  - Lists become an attrset of boolean flags keyed by list entries

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
    listToAttrs (
      map
      (name: {
        inherit name;
        value = set.${name};
      })
      (
        builtins.filter
        (name: predicate name set.${name})
        (attrNames set)
      )
    );

  /**
  Inherit a named attribute from a source attrset when it exists.

  Supports two call forms:
  - Curried: `inheritOne name set`
  - Attrset: `inheritOne { name = ...; set = ...; }`

  # Type

  ```nix
  inheritOne :: String -> { ... } -> { ... }
  inheritOne :: { name :: String; set :: { ... }; ... } -> { ... }
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
  inheritOne "flake" { flake = { a = 1; }; }
  # => { flake = { a = 1; }; }

  inheritOne "flake" {}
  # => {}
  ```
  */
  inheritOne = nameOrArgs:
    if isAttrs nameOrArgs
    then let
      name = nameOrArgs.name or null;
      set = nameOrArgs.set or null;
    in
      if name == null || set == null
      then throw "attrsets.inheritOne:= expected { name, set; }"
      else if hasAttr name set
      then {${name} = getAttr name set;}
      else {}
    else
      set:
        if hasAttr nameOrArgs set
        then {${nameOrArgs} = getAttr nameOrArgs set;}
        else {};

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
    if isAttrs value && isNotEmpty value
    then value
    else {};

  /**
  Recursively merge two attrsets.

  When both sides contain an attrset at the same key, they are merged
  recursively. Otherwise the right-hand value wins.

  # Type

  ```nix
  update :: AttrSet -> AttrSet -> AttrSet
  ```

  # Dependencies

  - attrsets.update

  # Arguments

  lhs
  : The base attrset.

  rhs
  : The overriding attrset.

  # Examples

  ```nix
  update { a.b = 1; } { a.c = 2; }
  # => { a = { b = 1; c = 2; }; }
  ```
  */
  update = lhs: rhs:
    if isAttrs lhs && isAttrs rhs
    then
      listToAttrs (
        map
        (key: {
          name = key;
          value =
            if lhs ? ${key} && rhs ? ${key}
            then update lhs.${key} rhs.${key}
            else if rhs ? ${key}
            then rhs.${key}
            else lhs.${key};
        })
        (attrNames (lhs // rhs))
      )
    else rhs;

  /**
  Pick the first value from an attrset.

  Returns `null` when the attrset is empty.

  # Type

  ```nix
  findFirst :: AttrSet -> a | null
  ```

  # Dependencies

  None

  # Arguments

  attrs
  : The attrset to inspect.

  # Examples

  ```nix
  findFirst {}
  # => null

  findFirst { a = 1; }
  # => 1
  ```
  */
  findFirst = attrs:
    if attrs == {}
    then null
    else head (attrValues attrs);
in
  exports
