{
  debug,
  lists,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit isFunction' asFloat toFloat;
      to = {float = toFloat;};
      from = {};
      as = {float = asFloat;};
    };
    global = {
      inherit isEmpty isEnabled isFunction' isNotEmpty isNotNull isNull toFloat;
      asFloatType = asFloat;
    };
  };

  inherit (debug) withContext;
  inherit (lists) head tail isList optionals reverseList;
  inherit (strings) concatStrings fromJSON stringLength stringToCharacters;
  inherit (types) coercedTo float int isAttrs isBool isFloat isInt str typeOf isString;

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
  isFunction' = value: let
    inherit (builtins) isFunction;
  in
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

  # Rules
  - `null`:             always empty
  - Strings:            empty when `""` or whitespace-only
  - Lists:              empty when `[]`
  - Attrsets:           empty when `{}`
  - Numbers, booleans, paths, functions: **never** empty
  - Functions: unsupported and cause an error

  # Type
  ```nix
  isEmpty :: a -> Bool
  ```

  # Dependencies
  - strings.trim

  # Arguments
  value
  : The value to test.

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

  # Dependencies
  - types.isEmpty

  # Arguments
  value
  : The value to test.

  # Examples
  ```nix
  isNotEmpty "hello"  # => true
  isNotEmpty 0        # => true
  isNotEmpty false    # => true
  isNotEmpty null     # => false
  isNotEmpty ""       # => false
  isNotEmpty []       # => false

  # Common use in filters
  validItems = filter isNotEmpty rawList;
  ```
  */
  isNotEmpty = value: !isEmpty value;

  /**
  Convert a value to a float.

  Accepts `int`, numeric `str`, or `float`. Strings are parsed via
  `fromJSON` and validated before coercion. Non-numeric strings
  throw a descriptive error.

  # Type
  ```nix
  toFloat :: int | str | float -> float
  ```

  # Dependencies
  ```nix
  types.isFloat
  types.isInt
  types.isString
  strings.fromJSON
  ```

  # Arguments
  value
  : The value to convert.

  #Examples
  > toFloat 1
  => 1.0

  > toFloat "3.14"
  => 3.14

  > toFloat 2.5
  => 2.5

  > toFloat "not a number"
  => error: toFloat: cannot convert string 'not a number' to a number
  */
  toFloat = value: let
    _name = "types::toFloat";
    _args = {
      inherit value;
      type = typeOf value;
    };
  in
    if isFloat value
    then value
    else if isInt value
    then value * 1.0
    else if isString value
    then let
      parsed = fromJSON value;
    in
      if isFloat parsed || isInt parsed
      then parsed * 1.0
      else throw "${_name}: Cannot convert string '${_args.value}' to a number"
    else throw "${_name}: Unsupported type: ${_args.type}";

  /**
  Option type that coerces values to float.

  For use in lib.mkOption { type = ...; }. Accepts the same inputs as
  toFloat but is a coercedTo type definition rather than a callable
  function.

  # Type
  ```nix
  asFloat :: option-type
  ```

  # Dependencies
  ```nix
  types.coercedTo
  types.int
  types.str
  types.float
  strings.fromJSON
  types.isFloat
  types.isInt
  ```

  # Examples
  ```nix
  lib.mkOption {
    type = asFloat;
    default = 0.5;
  }

  # All of these are valid values for the option:
  > threshold = 0.5;      # float — passed through
  > threshold = 1;        # int   — coerced to 1.0
  > threshold = "2.5";    # str   — coerced to 2.5
  */
  asFloat = let
    _name = "types::asFloat";
    fromInt = value: value * 1.0;
    fromStr = value: let
      parsed = fromJSON value;
    in
      if isFloat parsed || isInt parsed
      then parsed * 1.0
      else throw "${_name}: cannot convert string '${value}' to a number";
  in
    coercedTo int fromInt (coercedTo str fromStr float);
in
  exports
