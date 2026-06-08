let
  exports = {
    scoped = {
      inherit
        trim
        orEmpty
        ;
    };

    global = {
      trimString = trim;
      orEmptyString = orEmpty;
    };
  };

  inherit
    (builtins)
    head
    isString
    match
    stringLength
    ;

  /**
  Trim leading and trailing whitespace from a string.

  Non-string values are treated as the empty string.

  # Type

  ```nix
  trim :: a -> String
  ```

  # Dependencies

  None

  # Arguments

  value
  : The value to trim. Non-string values produce `""`.

  # Examples

  ```nix
  trim "  hello  "
  # => "hello"

  trim "\n  hi there\t"
  # => "hi there"

  trim null
  # => ""
  ```
  */
  trim = value: let
    string =
      if isString value
      then value
      else "";

    matches = match "[[:space:]]*(.*[^[:space:]])?[[:space:]]*" string;
  in
    if matches != null
    then head matches
    else "";

  /**
  Return a non-empty string as-is, otherwise return `""`.

  Strings containing only whitespace are treated as empty.

  # Type

  ```nix
  orEmpty :: a -> String
  ```

  # Dependencies

  - strings.trim

  # Arguments

  value
  : The value to normalize.

  # Examples

  ```nix
  orEmpty "hello"
  # => "hello"

  orEmpty "   "
  # => ""

  orEmpty null
  # => ""
  ```
  */
  orEmpty = value:
    if isString value && stringLength (trim value) > 0
    then value
    else "";
in
  exports
