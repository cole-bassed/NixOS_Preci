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
      inherit as asIf asModule foldl orEmpty unique concatUnique concat;
      maps = concatMap;
      at = elemAt;
      first = head;
      initial = head;
      remaining = tail;
      isIn = elem;
      select = filter;
      generate = genList;
    };

    global = {
      optionalList = asIf;
      asModuleList = asModule;
      asList = as;
      asListIf = asIf;
      orEmptyList = orEmpty;
      uniqueList = unique;
      listLength = length;
      inherit (builtins) concatLists concatMap genList isList;
    };
  };

  inherit
    (builtins)
    attrNames
    concatMap
    elem
    elemAt
    filter
    genList
    head
    isAttrs
    isFunction
    isList
    isString
    length
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
  as = args: let
    isConfig =
      isAttrs args && args ? value;
    value =
      if isConfig
      then args.value
      else args;
    default =
      if isConfig && args ? default
      then args.default
      else [];
    fatal =
      if isConfig && args ? fatal
      then args.fatal
      else false;
    result =
      if isList value
      then value
      else if isString value
      then [value]
      else if isFunction value
      then [value]
      else if isAttrs value
      then
        if (args.wrapAttrs or false)
        then [value]
        else attrNames value
      else if typeOf value == "path"
      then [value]
      else null;
  in
    if result != null
    then result
    else if fatal
    then throw "lists.as: unsupported type: ${typeOf value}"
    else default;

  asModule = value:
    as {
      inherit value;
      default = [];
      wrapAttrs = true;
    };

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

  /**
  Flatten, coerce, and filter out nulls/invalids from a list of inputs.
  Each input can be a raw value or a nested list. They are all safely
  passed through `as` to coerce them to lists, and invalid types/nulls
  are quietly dropped.

  # Type
  ```nix
  concat :: [ any ] -> [ any ]
  */
  concat = list:
    concatMap (
      value:
        filter (item: item != null) (
          if isList value
          then map (item: asModule {value = item;}) value
          else asModule {inherit value;}
        )
    ) (orEmpty list);

  /**
  Performs concat and deduplicates the final output.
  */
  concatUnique = list: unique (concat list);
in
  exports
