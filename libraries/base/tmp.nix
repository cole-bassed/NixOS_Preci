_: let
  exports = {
    scoped = {
      inherit
        (builtins)
        all
        any
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
      inherit
        as
        asIf
        lastOf
        firstOf
        asModule
        asUnique
        foldl
        orEmpty
        unique
        unique'
        concatUnique
        concat
        ;
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
      asUniqueList = asUnique;
      orEmptyList = orEmpty;
      uniqueList = unique;
      uniqueListUnordered = unique';
      uniqueListOfStrings = unique';
      listLength = length;
      concatLists' = concat;
      concatUniqueLists = concatUnique;
      inherit (builtins) concatMap genList isList;
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
    groupBy
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
  unique' = list: attrNames (groupBy (x: x) list);
  asUnique = list: unique (as list);

  /**
    Flatten, coerce, and filter out nulls/invalids from a list of inputs.
    Each input can be a raw value or a nested list. They are all safely
    passed through `as` to coerce them to lists, and invalid types/nulls
    are quietly dropped.

    # Type
  ```nix
    concat :: [ any ] -> [ any ]

    Supports:
      - Explicit AttrSet: { list; includes ?; excludes ?; }
      - Curried (Includes List) -> (List): a bare list of allowed type names,
        returning a function awaiting the actual data list.
      - Simple List (Default Policy): a bare data list, using default includes.

    NOTE: patterns 2 and 3 both begin with a plain list and are not
    structurally distinguishable, so a bare-list argument is always treated
    as pattern 2 (an `includes` filter awaiting the data list next). Callers
    wanting pattern 3 semantics should use the explicit attrset form
    (`concat { list = [...]; }`) instead of passing a bare list directly.
  */
  concat = arg: let
    # Define the core logic
    exec = {
      list,
      includes ? null,
      excludes ? [],
    }: let
      defaultIncludes = ["string" "list" "int" "float" "bool" "path"];
      allowed =
        if includes != null
        then includes
        else defaultIncludes;

      isAllowed = value: let
        t = typeOf value;
      in
        (elem t allowed) && !(elem t excludes);

      flatten = value:
        if isList value
        then concatMap flatten value
        else if value == null
        then []
        else if isAllowed value
        then [value]
        else [];
    in
      unique (flatten list);
  in
    #? Pattern 1: Explicit AttrSet
    if isAttrs arg && (arg ? list)
    then exec arg
    #? Pattern 2: Curried (Includes List) -> (List)
    #~@ NOTE: this branch also catches bare data lists (former "Pattern 3"),
    #~@ since a plain list can't be told apart from an includes-list. See
    #~@ docstring above.
    else if isList arg
    then
      list:
        exec {
          inherit list;
          includes = arg;
        }
    #? Fallback
    else exec {list = [];};

  /**
  Performs concat and deduplicates the final output.
  */
  concatUnique = list: unique (concat list);

  lastOf = list:
    if isList list
    then elemAt list ((length list) - 1)
    else null;
  firstOf = list:
    if isList list
    then head list
    else null;
in
  exports
