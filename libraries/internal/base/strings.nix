_: let
  exports = {
    scoped = {
      inherit
        concat
        orEmpty
        quote
        split'
        trim
        trimStart
        trimEnd
        trimBoth
        trim'
        trimAll
        has
        hasPrefix
        hasInfix
        hasSuffix
        ;
      startsWith = hasPrefix;
      endsWith = hasSuffix;
      contains = hasInfix;
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
      inherit hasInfix hasPrefix hasSuffix quote;
      hasString = has;
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
    elem
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
    typeOf
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

  has = arg: let
    _name = "string::has";
    modes = ["start" "contains" "end"];

    assertString = _arg: input:
      if isString input
      then input
      else throw "${_name}: ${_arg} must be a string, got ${typeOf input}";

    exec = mode: check: value: let
      mode' = let
        string = assertString "mode" mode;
        isValid = elem string modes;
      in {inherit string isValid;};

      value' = let
        string = assertString "value" value;
        length = stringLength string;
      in {inherit string length;};

      check' = let
        string = assertString "check" check;
        length = stringLength string;
        escaped =
          replaceStrings
          ["\\" "." "+" "*" "?" "^" "$" "(" ")" "[" "]" "{" "}" "|"]
          ["\\\\" "\\." "\\+" "\\*" "\\?" "\\^" "\\$" "\\(" "\\)" "\\[" "\\]" "\\{" "\\}" "\\|"]
          string;
        contains = ".*${escaped}.*";
      in {inherit contains escaped string length;};
    in
      if mode'.isValid
      then
        if mode'.string == "start"
        then substring 0 check'.length value'.string == check'.string
        else if mode'.string == "contains"
        then match check'.contains value'.string != null
        else let
          suffix =
            substring
            (value'.length - check'.length)
            check'.length
            value'.string;
        in
          value'.length
          >= check'.length
          && suffix == check'.string
      else throw "${_name}: mode must be one of ${concat ", " (map quote modes)}";
  in
    if isAttrs arg
    then exec arg.mode arg.check arg.value
    else check: value: exec arg check value;
  hasPrefix = has "start";
  hasInfix = has "contains";
  hasSuffix = has "end";

  trim = arg: let
    _name = "string::trim";
    modes = ["start" "end" "both" "all"];

    assertString = _arg: input:
      if isString input
      then input
      else throw "${_name}: ${_arg} must be a string, got ${typeOf input}";

    # When called as: trim mode: value
    # We treat arg as mode, and pattern/value as deferred.
    maybeCurriedMode = arg;

    # Private execution: pattern-aware trim
    exec = mode: pattern: value: let
      mode' = let
        string = assertString "mode" mode;
        isValid = elem string modes;
      in {inherit string isValid;};

      value' = let
        string = assertString "value" value;
      in {inherit string;};

      # Default pattern to whitespace if not provided
      pattern' =
        if isString pattern && pattern != ""
        then pattern
        else "[[:space:]]";

      # For "all", we'll do edge trim + collapse internal
      trimmedStart =
        if mode' == "start" || mode' == "both" || mode' == "all"
        then
          # Remove leading occurrences of pattern
          let
            regex = "${pattern'}*";
            result = match "^${regex}(.*)$" value'.string;
          in
            if result == null
            then value'.string
            else head result
        else value'.string;

      trimmedEnd =
        if mode' == "end" || mode' == "both" || mode' == "all"
        then let
          regex = "(.*)${pattern'}*$";
          result = match regex trimmedStart;
        in
          if result == null
          then trimmedStart
          else head result
        else trimmedStart;

      collapsed =
        if mode' == "all"
        then let
          regex = "${pattern'}+";
          result = replaceStrings [regex] [pattern'] trimmedEnd;
          # Collapse to single space if pattern is whitespace
          normalized =
            if pattern' == "[[:space:]]"
            then replaceStrings ["  "] [" "] (replaceStrings ["   "] ["  "] result)
            else result;
        in
          normalized
        else trimmedEnd;
    in
      if mode'.isValid
      then collapsed
      else throw "${_name}: mode must be one of ${concat ", " (map quote modes)}";
  in
    if isAttrs arg
    then exec arg.mode (arg.pattern or "[[:space:]]") arg.value
    else if isString maybeCurriedMode
    then
      # trim mode: value
      value: exec maybeCurriedMode "[[:space:]]" value
    else
      # trim mode: pattern: value
      pattern: value: exec maybeCurriedMode pattern value;

  trimStart = trim "start";
  trimEnd = trim "end";
  trimBoth = trim "both";
  trimAll = trim "all";
  trim' = value: trim "both" value;

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
