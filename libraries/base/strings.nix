{
  attrsets,
  trivial,
  lists,
  ...
}: let
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
    all
    concatStringsSep
    elem
    elemAt
    filter
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

  inherit (attrsets) namesOf valuesOf;
  inherit (lists) asList lastOf;
  inherit (trivial) makeHybrid readHybrid;

  defaults.modes = let
    set = {
      start = "start";
      contains = "contains";
      end = "end";
      both = "both";
      all = "all";
    };
  in
    set
    // {
      names = namesOf set;
      values = valuesOf set;
    };

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
  ```

  # Dependencies
  - builtins.concatStringsSep
  - builtins.filter
  - builtins.isAttrs
  - builtins.isString
  - builtins.isList

  # Arguments
  arg
  : An configuration attribute set { delim ?, parts }, a delimiter string, or a direct list of string parts.

  # Examples
  - __Pattern 1__: _Explicit Attribute Set Configuration_

  > concat { delim = "-"; parts = [ "foo" "bar" ]; }
  => "foo-bar"

  - __Pattern 2__: _Curried Positional (Delimiter then Parts)_

  > concat "/" [ "usr" "local" "bin" ]
  => "usr/local/bin"

  - __Pattern 3__: _Shorthand List (Omits Delimiter)_

  > concat [ "a" "b" "c" ]
  => "abc"

  - __Built-in Null Safety__

  > concat { delim = "_"; parts = [ "core" null "system" ]; }
  => "core_system"
  */
  concat = arg: let
    positional = ["delim" "parts"];
    primary = lastOf positional;
    function =
      makeHybrid {
        inherit positional primary;
        fallback = isList;
      } (
        payload: let
          args = readHybrid {
            inherit payload;
            required = [primary];
            defaults.delim = "";
          };
        in
          concatStringsSep
          args.delim
          (filter (part: part != null) (asList args.parts))
      );
  in
    function arg;
  # concat = arg: let
  #   required = ["delim" "parts"];
  #   priority = lastOf required;
  # in
  #   (
  #     makeHybrid {
  #       positional = required;
  #       primary = priority;
  #       fallback = isList;
  #     } (payload: let
  #       args = readHybrid {
  #         inherit payload;
  #         required = asList priority;
  #         defaults = {delim = "";};
  #       };
  #     in
  #       concatStringsSep
  #       args.delim
  #       (filter (part: part != null) (asList args.parts)))
  #   )
  #   arg;

  # concat = let
  #   required = ["delim" "parts"];
  #   priority = lastOf required;
  # in
  #   makeHybrid {
  #     positional = required;
  #     primary = priority;
  #     fallback = isList;
  #   } (payload: let
  #     args = readHybrid {
  #       inherit payload;
  #       required = asList priority;
  #       defaults = {delim = "";};
  #     };
  #   in
  #     concatStringsSep
  #     args.delim
  #     (filter (part: part != null) (asList args.parts)));

  has = arg: let
    _name = "string::has";
    modes = defaults.modes.names;
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

  trim = let
    _name = "strings.trim";
    required = ["mode" "pattern" "value"];
    priority = lastOf required;
    inherit (defaults) modes;
  in
    makeHybrid {
      positional = required;
      primary = priority;
    } (
      payload: let
        #> Explode and validate arguments using the unified infrastructure
        args = readHybrid {
          inherit payload;
          required = asList priority;
          defaults = {
            mode = "both";
            pattern = "[[:space:]]";
          };
        };

        #> Strict type compliance checks
        check = let
          is_string = all isString (with args; [mode pattern value]);
          is_mode = elem args.mode modes.names;
          is_pattern = args.pattern != "";
        in
          if !is_string
          then throw "${_name}: parameters (mode, pattern, value) must all be strings"
          else if !is_mode
          then throw "${_name}: mode must be one of ${concat ", " (map quote modes.names)}"
          else if !is_pattern
          then throw "${_name}: pattern cannot be an empty string"
          else true;

        #> 3. Functional trimming phases
        process = assert check; {
          start = value: let
            matches = match "^(${args.pattern})*(.*)$" value;
          in
            if matches == null
            then value
            else elemAt matches 1;

          end = value: let
            #> Capture everything up to the last non-matching character
            matches = match "^(.*[^${args.pattern}]+)(${args.pattern})*$" value;
          in
            #? Fallback: if it's null, the string is either empty or entirely spaces
            if matches == null
            then ""
            else elemAt matches 0;

          all = value: let
            #> For 'all', completely remove the pattern globally using split
            parts = split args.pattern value;
          in
            #> Filter out matching lists and recombine the non-matching string segments
            concat (filter isString parts);
        };

        #> Determine application mapping
        result =
          if args.mode == modes.start
          then process.start args.value
          else if args.mode == modes.end
          then process.end args.value
          else if args.mode == modes.both
          then process.end (process.start args.value)
          else if args.mode == modes.all
          then process.all args.value
          else args.value;
      in
        result
    );

  trimStart = trim "start";
  trimEnd = trim "end";
  trimBoth = trim "both";
  trimAll = trim "all";
  trim' = value: trimBoth "[[:space:]]" value;

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
