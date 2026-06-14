{
  attrsets,
  types,
  ...
}: let
  exports = {
    scoped =
      {
        inherit
          asIf
          orEmpty
          unique
          foldl
          head
          tail
          as
          ;
        first = head;
        initial = head;
        remaining = tail;
        concat = concatLists;
        isIn = builtins.elem;
        select = filter;
        inherit (builtins) sort filter;
      }
      // exports.global;

    global = {
      inherit concatLists foldl isList;
      asList = as;
      asListIf = asIf;
      orEmptyList = orEmpty;
      uniqueList = unique;
    };
  };

  inherit (builtins) concatLists filter head isAttrs tail;
  inherit (attrsets) namesOf;
  inherit (types) isList isNotEmpty isString typeOf;

  /**
  Coerce a value into a list.

  Supported inputs:
  - Lists are returned unchanged
  - Strings are wrapped as singleton lists
  - Attrsets become `attrNames value`
  - Paths are wrapped as singleton lists

  # Type

  ```nix
  asList :: [ a ] | String | AttrSet | Path -> [ a ]
  ```

  # Dependencies

  None

  # Arguments

  value
  : The value to coerce.

  # Examples

  ```nix
  asList "pop"
  # => [ "pop" ]

  asList { a = 1; b = 2; }
  # => [ "a" "b" ]

  asList ./file.nix
  # => [ ./file.nix ]
  ```
  */
  as = value: let
    type = typeOf value;
  in
    if isList value
    then value
    else if isString value
    then [value]
    else if isAttrs value
    then namesOf value
    else if type == "path"
    then [value]
    else throw "lists.as:= unsupported type: ${type}";

  /**
  Conditionally coerce a value into a list.

  Returns `as value` when `predicate` is true, otherwise `[]`.

  # Type

  ```nix
  asIf :: Bool -> a -> [ b ]
  ```

  # Dependencies

  - lists.as

  # Arguments

  predicate
  : Whether coercion should happen.

  value
  : The value to coerce when enabled.

  # Examples

  ```nix
  asIf true "debug"
  # => [ "debug" ]

  asIf false "debug"
  # => []
  ```
  */
  asIf = predicate: value:
    if predicate
    then as value
    else [];

  /**
  Returns the original value only when:
    - the value is a list
    - the list is not empty

  Otherwise returns `[]`.

    # Type

    ```nix
    orEmpty :: a -> [ b ]
    ```

    # Dependencies

    - types.isNotEmpty

    # Arguments

    value
    : The value to normalize.

    # Examples

    ```nix
    orEmpty [ 1 2 ]
    # => [ 1 2 ]

    orEmpty []
    # => []

    orEmpty null
    # => []
    ```
  */
  orEmpty = value:
    if isList value && isNotEmpty value
    then value
    else [];

  /**
  Deduplicate a list while preserving first occurrence order.

  # Type

  ```nix
  unique :: [ a ] -> [ a ]
  ```

  # Dependencies

  - lists.unique

  # Arguments

  list
  : The list to deduplicate.

  # Examples

  ```nix
  unique [ 1 2 1 3 ]
  # => [ 1 2 3 ]
  ```
  */
  unique = list:
    if list == []
    then []
    else
      [(head list)]
      ++ unique (
        filter
        (value: value != (head list))
        (tail list)
      );

  foldl = input: let
    exec = fn: initial: list: let
      recurse = accumulated: remaining:
        if remaining == []
        then accumulated
        else let
          item = head remaining;
        in
          recurse (fn accumulated item) (tail remaining);
    in
      recurse initial list;
  in
    if isAttrs input
    then exec input.fn input.initial input.list
    else fn: initial: list: exec fn initial list;
in
  exports
