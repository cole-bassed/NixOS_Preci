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
        trim'
        trimStart
        trimEnd
        trimBoth
        trimAll
        has
        hasPrefix
        hasInfix
        hasSuffix
        ;
      contains = hasInfix;
      endsWith = hasSuffix;
      infix = substring;
      length = stringLength;
      regex = match;
      split = split';
      startsWith = hasPrefix;
      trim = trim';
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
      trimString = trim';
    };
  };

  inherit
    (builtins)
    concatStringsSep
    elem
    elemAt
    filter
    isList
    isString
    match
    length
    head
    replaceStrings
    split
    stringLength
    substring
    typeOf
    ;
  inherit (attrsets) namesOf valuesOf;
  inherit (lists) asList lastOf;
  inherit (trivial) makeHybrid readHybrid buildFunction;

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
  concat = buildFunction {
    name = "strings.concat";
    positional = ["delim" "parts"];
    required = ["parts"];
    optional = ["delim"];
    defaults = {delim = "";};
    fallback = isList; #> a bare list argument is treated as `parts` directly

    validation = {};

    simulation = [
      {
        args = {
          delim = "-";
          parts = ["foo" "bar"];
        };
        desired = "foo-bar";
      }
      {
        args = ["/" ["usr" "local" "bin"]];
        desired = "usr/local/bin";
      }
      {
        args = [["a" "b" "c"]];
        desired = "abc";
      }
      {
        args = {
          delim = "_";
          parts = ["core" null "system"];
        };
        desired = "core_system";
      }
    ];

    execution = args:
      concatStringsSep
      args.delim
      (filter (part: part != null) (asList args.parts));
  };

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
  trim' = let
    _name = "strings.trim";
    _modes = _defaults.modes;
  in
    buildFunction {
      name = _name;
      positional = ["value" "pattern" "mode"];
      required = ["value"];

      defaults = {
        mode = "both";
        pattern = "[[:space:]]";
      };

      simulation = [
        #> Single positional value: mode defaults to "both", pattern defaults to whitespace
        {
          args = "   hello   ";
          desired = "hello";
        }

        #> Two positional: value, pattern (mode defaults to "both")
        {
          args = {
            value = "hello";
            pattern = "l";
          };
          desired = "hello";
        }

        #> Three positional: value, pattern, mode
        {
          args = ["hello" "l" "every"];
          desired = "heo";
        }

        #> Mode alias: "all" canonicalizes to "every"
        {
          args = ["hello" "l" "all"];
          desired = "heo";
        }

        #> Mode alias: "each" canonicalizes to "both"
        {
          args = ["   hello   " "[[:space:]]" "each"];
          desired = "hello";
        }

        #> start mode: trims only leading matches
        {
          args = ["   hello   " "[[:space:]]" "start"];
          desired = "hello   ";
        }

        #> end mode: trims only trailing matches
        {
          args = ["   hello   " "[[:space:]]" "end"];
          desired = "   hello";
        }

        #> Attrs form, value only
        {
          args = {value = "   hello   ";};
          desired = "hello";
        }

        #> Attrs form, value + pattern
        {
          args = {
            value = "hello";
            pattern = "l";
          };
          desired = "helo";
        }

        #> Attrs form, all three explicit
        {
          args = {
            value = "hello";
            pattern = "l";
            mode = "every";
          };
          desired = "heo";
        }

        #> Error: mode must be non-empty
        {
          args = ["hello" "l" ""];
          throws = true;
        }

        #> Error: mode must be a recognized name
        {
          args = ["hello" "l" "not-a-mode"];
          throws = true;
        }

        #> Error: value must be a non-empty string
        {
          args = {value = "";};
          throws = true;
        }

        #> Error: too many positional arguments
        {
          args = ["hello" "l" "every" "extra"];
          throws = true;
        }
      ];

      validation = let
        validateString = name: value: let
          check = isString value && value != "";
          error = throw "${_name}: ${name} must be a non-empty string";
        in
          if check
          then value
          else error;

        canonicalMode = input:
          if input == _modes.all
          then _modes.every
          else if input == _modes.each
          then _modes.both
          else input;

        validateMode = input: let
          name = "mode";
          value = validateString name input;
          check = elem value _modes.names;
          error = throw "${_name}: ${name} must be one of ${concat ", " _modes.names}";
        in
          if check
          then canonicalMode value
          else error;
      in {
        mode = {
          validate = input: validateMode input;
          options = _modes.names;
          type = "enum";
        };
        pattern = input: validateString "pattern" input;
        value = input: validateString "value" input;
      };

      execution = args: let
        inherit (args) mode value pattern;

        start = {
          value,
          pattern,
        }: let
          parts = split "^(${pattern})+" value;
        in
          if length parts > 1
          then elemAt parts 2
          else head parts;

        end = {
          value,
          pattern,
        }: let
          parts = split "(${pattern})+$" value;
        in
          head parts;

        every = {
          value,
          pattern,
        }: let
          parts = split pattern value;
        in
          concat (filter isString parts);

        both = {
          value,
          pattern,
        }:
          start {
            value = end {inherit value pattern;};
            inherit pattern;
          };
      in
        if mode == _modes.start
        then start {inherit value pattern;}
        else if mode == _modes.end
        then end {inherit value pattern;}
        else if mode == _modes.both || mode == _modes.each
        then both {inherit value pattern;}
        else if mode == _modes.all || mode == _modes.every
        then every {inherit value pattern;}
        else value;
    };

  split'' = sep: str: let
    #> List of all POSIX ERE special characters
    specialChars = ["\\" "." "+" "*" "?" "^" "$" "(" ")" "[" "]" "{" "}" "|"];

    #> Their escaped counterparts
    escapedChars = map (c: "\\${c}") specialChars;

    #> Safely escape the provided separator so it acts as a literal string
    escapedSep = replaceStrings specialChars escapedChars sep;

    #> Perform the split using the built-in regex split
    rawSplit = split escapedSep str;
  in
    #> Filter out the regex match lists, keeping only the string segments
    filter isString rawSplit;

  # trim' = value: trimBoth "[[:space:]]" value;

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
        trim' "start" args.pattern args.value
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
        trim' "end" args.pattern args.value
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
        trim' "both" args.pattern args.value
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
        trim' "all" args.pattern args.value
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
    if isString value && stringLength (trim' value) > 0
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
    positional = ["sep" "str"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };

        # List of all POSIX ERE special characters
        specialChars = ["\\" "." "+" "*" "?" "^" "$" "(" ")" "[" "]" "{" "}" "|"];

        # Their escaped counterparts
        escapedChars = map (c: "\\${c}") specialChars;

        # Safely escape the provided separator
        escapedSep = replaceStrings specialChars escapedChars args.sep;

        # Basic regex escaping for common delimiters like '.' or '-'
        # If your paths only use dots, escaping the dot is the main priority.
        # escapedSep =
        #   if args.sep == "."
        #   then "\\."
        #   else if args.sep == "*"
        #   then "\\*"
        #   else if args.sep == "+"
        #   then "\\+"
        #   else args.sep;

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
