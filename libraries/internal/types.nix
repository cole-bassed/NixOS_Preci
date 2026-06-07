{
  debug,
  lists,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {inherit isFunction';};
    global = {
      inherit
        isEmpty
        isNotEmpty
        isFunction'
        isNull
        isNotNull
        ;
      isFunctionSafe = isFunction';
    };
  };

  inherit (debug) withContext;
  inherit (lists) head tail isList optionals reverseList;
  inherit (strings) concatStrings stringLength stringToCharacters;
  inherit (types) isAttrs isString;
  # inherit (builtins) isFunction tryEval;

  isFunction' = builtins.isFunction;
  #: TODO: Not working, still throwing the functor error
  # isFunction' = value:
  #   isFunction value
  #   || (
  #     value ? __functor
  #     && (tryEval (isFunction (value.__functor value))).value
  #   );

  # Minimal local trim so predicates doesn't circularly depend on strings.
  trim = s: let
    chars = stringToCharacters s;
    isSpace = c: c == " " || c == "\t" || c == "\n" || c == "\r";
    dropWhile = pred: list:
      optionals (list != []) (
        if pred (head list)
        then dropWhile pred (tail list)
        else list
      );
    trimmed = dropWhile isSpace (reverseList (dropWhile isSpace (reverseList chars)));
  in
    concatStrings trimmed;

  isNull = value: value == null;
  isNotNull = value: value != null;

  /**
  Check if a value is considered "empty" for defaulting purposes.

  # Emptiness Rules
  - `null`:             always empty
  - Strings:            empty when `""` or whitespace-only
  - Lists:              empty when `[]`
  - Attrsets:           empty when `{}`
  - Numbers, booleans, paths, functions: **never** empty

  # Type
  ```nix
  isEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isEmpty null        # => true
  isEmpty ""          # => true
  isEmpty "  "        # => true
  isEmpty []          # => true
  isEmpty {}          # => true
  isEmpty 0           # => false
  isEmpty false       # => false
  isEmpty "hello"     # => false
  isEmpty [1 2 3]     # => false
  ```
  */
  isEmpty = value:
    assert withContext {
      name = "isEmpty";
      assertion = !isFunction' value;
      message = "functions are not supported";
      context = "evaluating isEmpty";
    };
      if value == null
      then true
      else if isString value
      then value == "" || stringLength (trim value) == 0
      else if isList value
      then value == []
      else if isAttrs value
      then value == {}
      else false;

  /**
  Check if a value is not empty. Convenience negation of `isEmpty`.

  # Type
  ```nix
  isNotEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isNotEmpty "hello"  # => true
  isNotEmpty 0        # => true
  isNotEmpty false    # => true
  isNotEmpty null     # => false
  isNotEmpty ""       # => false

  # Common use in filters
  validItems = filter isNotEmpty rawList;
  ```
  */
  isNotEmpty = value: !isEmpty value;
in
  exports
