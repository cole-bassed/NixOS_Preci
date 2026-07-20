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
      inherit
        hasInfix
        hasPrefix
        hasSuffix
        quote
        ;
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

  _defaults.modes = let
    name = "modes";
    value = {
      #~@ Basic
      start = "start";
      contains = "contains";
      end = "end";
      both = "both";
      every = "every";

      #~@ Aliases
      all = "all"; # alias of every
      each = "each"; # alias of both
    };
  in
    {
      inherit name value;
      names = namesOf value;
      values = valuesOf value;
    }
    // value;

  # TODO: Arguments should show delim and parts though. how will they caller know the accepted args?
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
  - __Explicit Attribute Set Configuration__

  > concat { delim = "-"; parts = [ "foo" "bar" ]; }
  => "foo-bar"

  - __Curried Positional (Delimiter then Parts)__

  > concat "/" [ "usr" "local" "bin" ]
  => "usr/local/bin"

  - __Shorthand List (Omits Delimiter)__

  > concat [ "a" "b" "c" ]
  => "abc"

  - __Built-in Null Safety__

  > concat { delim = "_"; parts = [ "core" null "system" ]; }
  => "core_system"
  */
  concat = arg: let
    positional = ["delim" "parts"];
    primary = lastOf positional;
    fallback = isList;
    function = makeHybrid {inherit fallback positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload positional;
          defaults.delim = "";
        };
      in
        concatStringsSep
        args.delim
        (filter (part: part != null) (asList args.parts))
    );
  in
    function arg;

  # TODO: Arguments should show mode, check, and value though. how will they caller know the accepted args?
  /**
  Test whether a string satisfies a positional match against a check string,
  according to a mode: `"start"` (prefix), `"contains"` (infix), or `"end"` (suffix).

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (mode, then check, then value).

  # Type
  ```nix
  has :: AttrSet -> Bool
  has :: String -> String -> String -> Bool
  ```

  # Dependencies
  - builtins.elem
  - builtins.match
  - builtins.replaceStrings
  - builtins.stringLength
  - builtins.substring
  - builtins.typeOf
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set { mode, check, value }, or the mode string
  ("start" | "contains" | "end") for curried positional invocation.

  # Examples
  - __Explicit Attribute Set Configuration__

  > has { mode = "start"; check = "foo"; value = "foobar"; }
  => true

  > has { mode = "contains"; check = "oob"; value = "foobar"; }
  => true

  > has { mode = "end"; check = "bar"; value = "foobar"; }
  => true

  - __Curried Positional (_Mode_, _Check_, _Value_)__

  > has "start" "foo" "foobar"
  => true

  > has "end" "bar" "foobar"
  => true

  > has "contains" "xyz" "foobar"
  => false

  - __Partial application__

  > startsWithFoo = has "start" "foo";
  > startsWithFoo "foobar"
  => true

  > startsWithFoo "barfoo"
  => false

  - __Invalid mode throws__

  > has "sideways" "foo" "foobar"
  => error: string::has: mode must be one of "start", "contains", "end", "both", "all"
  */
  has = arg: let
    _name = "strings.has";
    positional = ["mode" "check" "value"];
    primary = lastOf positional;

    inherit (_defaults) modes;

    assertString = _arg: input:
      if isString input
      then input
      else throw "${_name}: ${_arg} must be a string, got ${typeOf input}";

    exec = mode: check: value: let
      mode' = let
        string = assertString "mode" mode;
        isValid = elem string modes.names;
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
        if mode'.string == modes.start
        then substring 0 check'.length value'.string == check'.string
        else if mode'.string == modes.contains
        then match check'.contains value'.string != null
        else let
          suffix =
            substring
            (value'.length - check'.length)
            check'.length
            value'.string;
        in
          value'.length >= check'.length && suffix == check'.string
      else throw "${_name}: mode must be one of ${concat ", " (map quote modes.names)}";

    required = positional;
    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {inherit payload required;};
      in
        exec args.mode args.check args.value
    );
  in
    function arg;

  # TODO: Arguments should show check, and value though. how will they caller know the accepted args?
  /**
  Test whether a string starts with a given prefix. A hybrid partial application
  of `has` with `mode` pre-bound to `"start"`.

  # Type
  ```nix
  hasPrefix :: AttrSet -> Bool
  hasPrefix :: String -> String -> Bool
  ```

  # Dependencies
  - strings.has

  # Arguments
  arg
  : A configuration attribute set { check, value }, or the check (prefix) string
  for curried positional invocation.

  # Examples
  - __Explicit Attribute Set Configuration__

  > hasPrefix { check = "foo"; value = "foobar"; }
  => true

  > hasPrefix { check = "bar"; value = "foobar"; }
  => false

  - __Curried Positional (Check then Value)__

  > hasPrefix "foo" "foobar"
  => true

  - __Partial application__

  > startsWithFoo = hasPrefix "foo";
  > startsWithFoo "foobar"
  => true

  > startsWithFoo "barfoo"
  => false
  */
  hasPrefix = arg: let
    positional = ["check" "value"];
    primary = lastOf positional;
    required = positional;
    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {inherit payload required;};
      in
        has "start" args.check args.value
    );
  in
    function arg;

  # TODO: Arguments should show check, and value though. how will they caller know the accepted args?
  /**
  Test whether a string contains a given infix. A hybrid partial application
  of `has` with `mode` pre-bound to `"contains"`.

  # Type
  ```nix
  hasInfix :: AttrSet -> Bool
  hasInfix :: String -> String -> Bool
  ```

  # Dependencies
  - strings.has

  # Arguments
  arg
  : A configuration attribute set { check, value }, or the check (infix) string
  for curried positional invocation.

  # Examples
  - __Explicit Attribute Set Configuration__

  > hasInfix { check = "oob"; value = "foobar"; }
  => true

  > hasInfix { check = "xyz"; value = "foobar"; }
  => false

  - __Curried Positional (_Check_ then _Value_)__

  > hasInfix "oob" "foobar"
  => true

  - __Partial application__

  > containsOob = hasInfix "oob";
  > containsOob "foobar"
  => true

  > containsOob "hello"
  => false
  */
  hasInfix = arg: let
    positional = ["check" "value"];
    primary = lastOf positional;
    required = positional;
    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {inherit payload required;};
      in
        has "contains" args.check args.value
    );
  in
    function arg;

  # TODO: Arguments should show check, and value though. how will they caller know the accepted args?
  /**
  Test whether a string ends with a given suffix. A hybrid partial application
  of `has` with `mode` pre-bound to `"end"`.

  # Type
  ```nix
  hasSuffix :: AttrSet -> Bool
  hasSuffix :: String -> String -> Bool
  ```

  # Dependencies
  - strings.has

  # Arguments
  arg
  : A configuration attribute set { `check`, `value` }, or the check (suffix) string
  for curried positional invocation.

  # Examples
  - __Explicit Attribute Set Configuration__

  > hasSuffix { check = "bar"; value = "foobar"; }
  => true

  > hasSuffix { check = "foo"; value = "foobar"; }
  => false

  - __Curried Positional (Check then Value)__

  > hasSuffix "bar" "foobar"
  => true

  - __Partial application__

  > endsWithBar = hasSuffix "bar";
  > endsWithBar "foobar"
  => true

  > endsWithBar "barfoo"
  => false
  */
  hasSuffix = arg: let
    positional = ["check" "value"];
    primary = lastOf positional;
    required = positional;
    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {inherit payload required;};
      in
        has "end" args.check args.value
    );
  in
    function arg;

  /**
  Trim characters matching a pattern from a string, according to a mode:
  `"start"`, `"end"`, `"both"` (default), or `"all"` (global removal).

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (mode, then pattern, then value).

  # Type
  ```nix
  trim :: AttrSet -> String
  trim :: String -> String -> String -> String
  ```

  # Dependencies
  - builtins.elem
  - builtins.match
  - builtins.split
  - builtins.isString
  - trivial.makeHybrid
  - trivial.readHybrid
  - strings.concat

  # Arguments
  arg
  : A configuration attribute set { `mode` ?, `pattern` ?, `value` }, or the mode
  string for curried positional invocation. `mode` defaults to `"both"` and
  `pattern` defaults to `"[[:space:]]"`.

  # Examples
  - _Explicit Attribute Set Configuration (mode and pattern default)__

  > trim { mode = "start"; value = "  hello  "; }
  => "hello  "

  > trim { value = "  hello  "; }
  => "hello"

  - __Curried Positional (Mode, Pattern, Value)__

  > trim "start" "[[:space:]]" "  hello  "
  => "hello  "

  > trim "end" "[[:space:]]" "  hello  "
  => "  hello"

  > trim "both" "[[:space:]]" "  hello  "
  => "hello"

  > trim "all" "-" "-foo-bar-"
  => "foobar"

  - __Partial application__

  > trimDashesBoth = trim "both" "-";
  > trimDashesBoth "--hello--"
  => "hello"
  */
  trim = let
    _name = "strings.trim";
    _modes = _defaults.modes;

    defaults = {
      mode = "both";
      pattern = "[[:space:]]";
      value = null;
    };

    validate = let
      validateString = input: name: {
        check = input: isString input && input != "";
        error = throw "${_name}: ${name} must be a non-empty string";
      };
    in {
      mode = input: let
        base = validateString "mode" input;
      in
        base
        // {
          check = base.check && elem input _modes.names;
          error =
            if base.check
            then
              throw "${_name}: mode must be one of ${
                concat ", " (map quote _modes.names)
              }"
            else base.error;
        };
      pattern = input: validateString "pattern";
      value = input: validateString "value";
    };

    prep = mode: pattern: value: let
      start = let
        matches = match "^(${pattern})*(.*)$" value;
      in
        if matches == null
        then value
        else elemAt matches 1;

      end = let
        #> Capture everything up to the last non-matching character
        matches = match "^(.*[^${pattern}]+)(${pattern})*$" value;
      in
        #? Fallback: if it's null, the string is either empty or entirely spaces
        if matches == null
        then ""
        else elemAt matches 0;

      every = let
        #> For 'all', completely remove the pattern globally using split
        parts = split pattern value;
      in
        #> Filter out matching lists and recombine the non-matching string segments
        concat (filter isString parts);

      both = end (start value);
    in
      if mode == _modes.start
      then start
      else if mode == _modes.end
      then end
      else if mode == _modes.both || mode == _modes.each
      then both
      else if mode == _modes.all || mode == _modes.every
      then every
      else value;

    process = args: let
      mode = validate.mode (args.mode or defaults.mode);
      pattern = validate.pattern (args.pattern or defaults.pattern);
      value = validate.value (args.value or defaults.value);
    in
      prep mode pattern value;
  in
    args: process args;
  # mkHybrid {inherit defaults process};
  # makeHybrid {inherit positional primary defaults validate;}
  # (
  #   payload: let
  #     #> Explode and validate arguments using the unified infrastructure
  #     args = readHybrid {inherit defaults payload primary positional;};

  # #> Strict type compliance checks
  # check = let
  #   is_string = all isString (
  #     with args; [
  #       mode
  #       pattern
  #       value
  #     ]
  #   );
  #   is_mode = elem args.mode modes.names;
  #   is_pattern = args.pattern != "";
  # in
  #   if !is_string
  #   then throw "${_name}: parameters (mode, pattern, value) must all be strings"
  #   else if !is_mode
  #   then throw "${_name}: mode must be one of ${concat ", " (map quote modes.names)}"
  #   else if !is_pattern
  #   then throw "${_name}: pattern cannot be an empty string"
  #   else true;

  #   #> 3. Functional trimming phases
  #   process = assert check; {
  #     start = value: let
  #       matches = match "^(${args.pattern})*(.*)$" value;
  #     in
  #       if matches == null
  #       then value
  #       else elemAt matches 1;

  #     end = value: let
  #       #> Capture everything up to the last non-matching character
  #       matches = match "^(.*[^${args.pattern}]+)(${args.pattern})*$" value;
  #     in
  #       #? Fallback: if it's null, the string is either empty or entirely spaces
  #       if matches == null
  #       then ""
  #       else elemAt matches 0;

  #     all = value: let
  #       #> For 'all', completely remove the pattern globally using split
  #       parts = split args.pattern value;
  #     in
  #       #> Filter out matching lists and recombine the non-matching string segments
  #       concat (filter isString parts);
  #   };

  #   #> Determine application mapping
  #   result =
  #     if args.mode == modes.start
  #     then process.start args.value
  #     else if args.mode == modes.end
  #     then process.end args.value
  #     else if args.mode == modes.both
  #     then process.end (process.start args.value)
  #     else if args.mode == modes.all
  #     then process.all args.value
  #     else args.value;
  # in
  #   result
  # );

  trim' = value: trimBoth "[[:space:]]" value;

  /**
  Trim characters matching a pattern from the start of a string. A hybrid
  partial application of `trim` with `mode` pre-bound to `"start"`.

  # Type
  ```nix
  trimStart :: AttrSet -> String
  trimStart :: String -> String -> String
  ```

  # Dependencies
  - strings.trim

  # Arguments
  arg
  : A configuration attribute set { pattern ?, value }, or the pattern string
  for curried positional invocation. `pattern` defaults to `"[[:space:]]"`.

  # Examples
  - __Explicit Attribute Set Configuration (pattern defaults to whitespace)__

  > trimStart { value = "  hello"; }
  => "hello"

  > trimStart { pattern = "-"; value = "--hello"; }
  => "hello"

  - __Curried Positional (Pattern then Value)__

  > trimStart "-" "--hello"
  => "hello"

  - __Partial application__

  > trimDashesStart = trimStart "-";
  > trimDashesStart "--hello--"
  => "hello--"
  */
  trimStart = arg: let
    positional = ["pattern" "value"];
    primary = lastOf positional;
    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = [primary];
          defaults.pattern = "[[:space:]]";
        };
      in
        trim "start" args.pattern args.value
    );
  in
    function arg;

  /**
  Trim characters matching a pattern from the end of a string. A hybrid
  partial application of `trim` with `mode` pre-bound to `"end"`.

  # Type
  ```nix
  trimEnd :: AttrSet -> String
  trimEnd :: String -> String -> String
  ```

  # Dependencies
  - strings.trim

  # Arguments
  arg
  : A configuration attribute set { pattern ?, value }, or the pattern string
  for curried positional invocation. `pattern` defaults to `"[[:space:]]"`.

  # Examples
  - __Explicit Attribute Set Configuration (pattern defaults to whitespace)__

  > trimEnd { value = "hello  "; }
  => "hello"

  > trimEnd { pattern = "-"; value = "hello--"; }
  => "hello"

  - __Curried Positional (Pattern then Value)__

  > trimEnd "-" "hello--"
  => "hello"

  - __Partial application__

  > trimDashesEnd = trimEnd "-";
  > trimDashesEnd "--hello--"
  => "--hello"
  */
  trimEnd = arg: let
    positional = ["pattern" "value"];
    primary = lastOf positional;
    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = [primary];
          defaults.pattern = "[[:space:]]";
        };
      in
        trim "end" args.pattern args.value
    );
  in
    function arg;

  /**
  Trim characters matching a pattern from both ends of a string. A hybrid
  partial application of `trim` with `mode` pre-bound to `"both"`.

  # Type
  ```nix
  trimBoth :: AttrSet -> String
  trimBoth :: String -> String -> String
  ```

  # Dependencies
  - strings.trim

  # Arguments
  arg
  : A configuration attribute set { pattern ?, value }, or the pattern string
  for curried positional invocation. `pattern` defaults to `"[[:space:]]"`.

  # Examples
  - __Explicit Attribute Set Configuration (pattern defaults to whitespace)__

  > trimBoth { value = "  hello  "; }
  => "hello"

  > trimBoth { pattern = "-"; value = "--hello--"; }
  => "hello"

  - __Curried Positional (Pattern then Value)__

  > trimBoth "-" "--hello--"
  => "hello"

  - __Partial application__

  > trimDashesBoth = trimBoth "-";
  > trimDashesBoth "-foo-"
  => "foo"
  */
  trimBoth = arg: let
    positional = ["pattern" "value"];
    primary = lastOf positional;
    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = [primary];
          defaults.pattern = "[[:space:]]";
        };
      in
        trim "both" args.pattern args.value
    );
  in
    function arg;

  /**
  Trim all occurrences of a pattern from anywhere within a string. A hybrid
  partial application of `trim` with `mode` pre-bound to `"all"`.

  # Type
  ```nix
  trimAll :: AttrSet -> String
  trimAll :: String -> String -> String
  ```

  # Dependencies
  - strings.trim

  # Arguments
  arg
  : A configuration attribute set { pattern ?, value }, or the pattern string
  for curried positional invocation. `pattern` defaults to `"[[:space:]]"`.

  # Examples
  - __Explicit Attribute Set Configuration (pattern defaults to whitespace)__

  > trimAll { pattern = "-"; value = "-foo-bar-"; }
  => "foobar"

  > trimAll { value = "foo bar   baz"; }
  => "foobarbaz"

  - __Curried Positional (Pattern then Value)__

  > trimAll "-" "-foo-bar-"
  => "foobar"

  - __Partial application__

  > stripDashes = trimAll "-";
  > stripDashes "a-b-c-d"
  => "abcd"
  */
  trimAll = arg: let
    positional = ["pattern" "value"];
    primary = lastOf positional;
    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = [primary];
          defaults.pattern = "[[:space:]]";
        };
      in
        trim "all" args.pattern args.value
    );
  in
    function arg;

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

  Safe for bootstrap as it only relies on basic builtins. Supports the
  standard hybrid invocation patterns: an explicit configuration attribute
  set, or curried positional arguments (sep, then str).

  # Type
  ```nix
  split' :: AttrSet -> List String
  split' :: String -> String -> List String
  ```

  # Dependencies
  - builtins.filter
  - builtins.isString
  - builtins.split
  - trivial.makeHybrid
  - trivial.readHybrid

  # Arguments
  arg
  : A configuration attribute set { sep, str }, or the separator string for
  curried positional invocation.

  # Examples
  - __Pattern 1__: _Explicit Attribute Set Configuration_

  > split' { sep = "."; str = "a.b.c"; }
  => [ "a" "b" "c" ]

  - __Pattern 2__: _Curried Positional (Sep then Str)_

  > split' "/" "usr/local/bin"
  => [ "usr" "local" "bin" ]

  > split' "," "a,b,,c"
  => [ "a" "b" "" "c" ]

  - __Automatic escaping of regex-special delimiters (`.`, `*`, `+`)__

  > split' "." "a.b.c"
  => [ "a" "b" "c" ]

  - __Partial application__

  > splitOnDot = split' ".";
  > splitOnDot "a.b.c"
  => [ "a" "b" "c" ]

  > splitOnDot "no-dots-here"
  => [ "no-dots-here" ]
  */
  split' = arg: let
    positional = [
      "sep"
      "str"
    ];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };

        # Basic regex escaping for common delimiters like '.' or '-'
        # If your paths only use dots, escaping the dot is the main priority.
        escapedSep =
          if args.sep == "."
          then "\\."
          else if args.sep == "*"
          then "\\*"
          else if args.sep == "+"
          then "\\+"
          else args.sep;

        rawSplit = split escapedSep args.str;
      in
        filter isString rawSplit
    );
  in
    function arg;

  quote = value: let
    quoteOne = item: "\"" + replaceStrings ["\\" "\""] ["\\\\" "\\\""] (toString item) + "\"";
  in
    if isList value
    then "[ " + concatStringsSep " " (map quoteOne value) + " ]"
    else if isString value
    then quoteOne value
    else quoteOne value;
in
  exports
