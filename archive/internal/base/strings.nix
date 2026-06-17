_: let
  exports = {
    scoped = {
      inherit
        concat
        orEmpty
        quote
        split'
        trim
        ;
      startsWith = hasPrefix;
      infix = substring;
      length = stringLength;
      regex = match;
      split = split';
      wrap = quote;
    };

    global = {
      inherit
        (builtins)
        concatStringsSep
        replaceStrings
        stringLength
        substring
        toString
        ;
      inherit hasPrefix quote;
      joinStrings = concat;
      matchRegex = match;
      orEmptyString = orEmpty;
      splitString = split';
      trimString = trim;
    };
  };

  inherit
    (builtins)
    concatStringsSep
    filter
    head
    isAttrs
    isList
    isString
    match
    replaceStrings
    split
    stringLength
    substring
    ;

  /**
  Concatenate a list of strings with an optional delimiter, safely filtering out null values.

  Supports three hybrid invocation patterns: an explicit configuration attribute set,
  a curried positional layout (delimiter string then parts list), or a shorthand parts
  list (which defaults the delimiter to an empty string `""`).

  # Type
  ```nix
  concat :: AttrSet -> String
  concat :: String -> List String -> String
  concat :: List String -> String

  # Dependencies
  ```nix
  - builtins.concatStringsSep
  - builtins.filter
  - builtins.isAttrs
  - builtins.isString
  - builtins.isList
  ```

  # Arguments
  arg
  : An configuration attribute set { delim ?, parts }, a delimiter string, or a direct list of string parts.

  # Examples
  Nix
  # Pattern 1: Explicit Attribute Set Configuration
  concat { delim = "-"; parts = [ "foo" "bar" ]; }
  # => "foo-bar"

  # Pattern 2: Curried Positional (Delimiter then Parts)
  concat "/" [ "usr" "local" "bin" ]
  # => "usr/local/bin"

  # Pattern 3: Shorthand List (Omits Delimiter)
  concat [ "a" "b" "c" ]
  # => "abc"

  # Built-in Null Safety
  concat { delim = "_"; parts = [ "core" null "system" ]; }
  # => "core_system"
  */
  concat = arg: let
    exec = delim: parts:
      concatStringsSep delim (filter (part: part != null) parts);
  in
    if isAttrs arg
    then exec (arg.delim or "") arg.parts
    else if isString arg
    then parts: exec arg parts
    else if isList arg
    then exec "" arg
    else exec "" [];

  hasPrefix = prefix: string: let
    prefixLen = stringLength prefix;
  in
    prefixLen
    <= stringLength string
    && substring 0 prefixLen string == prefix;

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
  ```nix
  - strings.trim
  ```
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

  /**
  Splits a string by a literal string separator.
  Safe for bootstrap as it only relies on basic builtins.
  */
  split' = sep: str: let
    # Basic regex escaping for common delimiters like '.' or '-'
    # If your paths only use dots, escaping the dot is the main priority.
    escapedSep =
      if sep == "."
      then "\\."
      else if sep == "*"
      then "\\*"
      else if sep == "+"
      then "\\+"
      else sep;

    rawSplit = split escapedSep str;
  in
    filter isString rawSplit;

  quote = value: let
    quoteOne = item:
      "\""
      + replaceStrings ["\\" "\""] ["\\\\" "\\\""] (toString item)
      + "\"";
  in
    if isList value
    then "[ " + concatStringsSep " " (map quoteOne value) + " ]"
    else if isString value
    then quoteOne value
    else quoteOne value;
in
  exports
