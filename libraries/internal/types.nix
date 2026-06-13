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
        isEnabled
        ;
      isFunctionSafe = isFunction';
    };
  };

  inherit (debug) withContext;
  inherit (lists) head tail isList optionals reverseList;
  inherit (strings) concatStrings stringLength stringToCharacters;
  inherit (types) isAttrs isBool isString;
  inherit (builtins) isFunction;

  /**
  Determine if a module, feature, or configuration target is enabled.

  Follows the structural design principle of "presence implies intent." Naked
  booleans are evaluated directly. Attribute sets look for an explicit `enable`
  or `enabled` flag; if neither is specified, it is assumed the user wants the
  feature active, defaulting to `true`. All other fallback types evaluate to `true`.

  # Type
  ```nix
    isEnabled :: a -> Bool
  ```

  # Dependencies
  ```nix
  - types.isBool
  - types.isAttrs
  ```

  # Arguments
  value
  : The configuration toggle, attribute set, or value to evaluate.

  # Examples
  ```nix
  # Naked booleans pass through directly
  isEnabled true
  # => true

  isEnabled false
  # => false

  # Explicit overrides inside attribute sets
  isEnabled { enable = false; }
  # => false

  isEnabled { enabled = true; }
  # => true

  # Presence implies intent (no explicit toggle means true)
  isEnabled { userName = "John Doe"; }
  # => true

  # Fallback fail-safe for unexpected types
  isEnabled "active"
  # => true
  ```
  */
  isEnabled = value:
    if isBool value
    then value
    else if isAttrs value
    then value.enable or (value.enabled or true)
    else true;

  /**
  Strict check for callables, safely handling standard primitive functions
  and Nix attribute set functors without accidentally evaluating them.
  */
  isFunction' = value:
    isFunction value
    || (isAttrs value && value ? __functor && isFunction value.__functor);

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
