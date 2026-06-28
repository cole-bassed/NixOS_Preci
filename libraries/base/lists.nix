_: let
  exports = {
    scoped = {
      inherit
        (builtins)
        elem
        elemAt
        filter
        foldl'
        head
        length
        map
        optionalList
        partition
        sort
        tail
        zipAttrsWith
        ;
      inherit as asIf asModule foldl orEmpty unique;
      maps = builtins.concatMap;
      at = builtins.elemAt;
      first = head;
      initial = head;
      remaining = tail;
      concat = concatLists;
      isIn = elem;
      select = filter;
      generate = builtins.genList;
    };

    global = {
      optionalList = asIf;
      asModuleList = asModule;
      asList = as;
      asListIf = asIf;
      orEmptyList = orEmpty;
      uniqueList = unique;
      listLength = builtins.length;
      inherit (builtins) concatLists concatMap genList isList;
    };
  };

  inherit
    (builtins)
    attrNames
    concatLists
    elem
    filter
    head
    isAttrs
    isList
    isString
    tail
    typeOf
    ;

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
    then attrNames value
    else if type == "path"
    then [value]
    else throw "lists.as:= unsupported type: ${type}";

  asModule = value:
    if value == null
    then []
    else if isList value
    then value
    else [value];

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
    if isList value && value != []
    then value
    else [];

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
  unique = list: let
    exec = seen: rest:
      if rest == []
      then []
      else let
        x = head rest;
        xs = tail rest;
      in
        if elem x seen
        then exec seen xs
        else [x] ++ exec (seen ++ [x]) xs;
  in
    exec [] list;
in
  exports
