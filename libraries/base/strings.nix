{
  attrsets,
  assembly,
  lists,
  ...
}: let
  exports = {
    scoped = {
      inherit
        concat
        orEmpty
        quote
        split
        trim
        trimStart
        trimEnd
        trimEnds
        trimAll
        has
        hasPrefix
        hasInfix
        hasSuffix
        ;

      trimBoth = trimEnds;
      contains = hasInfix;
      endsWith = hasSuffix;
      infix = substring;
      length = stringLength;
      regex = match;
      startsWith = hasPrefix;
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
      inherit quote;
      hasPrefix' = hasPrefix;
      hasSuffix' = hasSuffix;
      hasInfix' = hasInfix;
      hasString = has;
      joinStrings = concat;
      matchRegex = match;
      orEmptyString = orEmpty;
      splitString = split;
      trimString = trim;
      split' = split;
      trim' = trim;
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
    stringLength
    substring
    typeOf
    ;
  splitOrig = builtins.split;
  inherit (assembly) mkFn;
  inherit (attrsets) namesOf valuesOf;
  inherit (lists) asList;

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
  - assembly.mkFn
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
  concat = mkFn {
    name = "strings.concat";
    positional = ["delim" "parts"];
    required = ["parts"];
    optional = ["delim"];
    defaults = {delim = "";};
    fallback = isList; #? a bare list argument is treated as `parts` directly

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

  /**
  Test whether a string satisfies a positional match against a pattern string,
  according to a mode: `"start"` (prefix), `"contains"` (infix), or `"end"` (suffix).

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (value, then pattern, then mode).
  The mode defaults to `"contains"`.

  # Type
  ```nix
  has :: AttrSet -> Bool
  has :: String -> String -> Bool
  has :: String -> String -> String -> Bool
  ```

  # Dependencies
  - assembly.mkFn
  - builtins.elem
  - builtins.match
  - builtins.replaceStrings
  - builtins.stringLength
  - builtins.substring
  - builtins.typeOf

  # Arguments
  value
  : The string to test. For explicit configuration, pass this as the `value`
  attribute.

  pattern
  : The string to match against `value`. For explicit configuration, pass this
  as the `pattern` attribute.

  mode
  : The positional match mode: `"start"`, `"contains"`, or `"end"`. For
  explicit configuration, pass this as the optional `mode` attribute. Defaults
  to `"contains"`.

  # Examples
  - __Explicit Attribute Set Configuration__

  > has { mode = "start"; pattern = "foo"; value = "foobar"; }
  => true

  > has { mode = "contains"; pattern = "oob"; value = "foobar"; }
  => true

  > has { mode = "end"; pattern = "bar"; value = "foobar"; }
  => true

  - __Curried Positional (_Value_, _Pattern_, optional _Mode_)__

  > has "foobar" "foo" "start"
  => true

  > has "foobar" "bar" "end"
  => true

  > has "foobar" "xyz"
  => false

  - __Partial application__

  > startsWithFoo = value: has value "foo" "start";
  > startsWithFoo "foobar"
  => true

  > startsWithFoo "barfoo"
  => false

  - __Invalid mode throws__

  > has "foobar" "foo" "sideways"
  => error: string::has: mode must be one of "start", "contains", "end", "both", "all"
  */
  has = let
    _name = "strings.has";
  in
    mkFn {
      name = _name;
      positional = ["value" "pattern" "mode"];
      required = ["value" "pattern"];
      optional = ["mode"];
      defaults = {mode = "contains";};

      validation = {
        mode = {
          validate = input:
            if !isString input
            then throw "${_name}: mode must be a string, got ${typeOf input}"
            else if !elem input _defaults.modes.names
            then throw "${_name}: mode must be one of ${concat ", " (map quote _defaults.modes.names)}"
            else input;
          options = _defaults.modes.names;
          type = "enum";
        };
        pattern = input:
          if isString input
          then input
          else throw "${_name}: pattern must be a string, got ${typeOf input}";
        value = input:
          if isString input
          then input
          else throw "${_name}: value must be a string, got ${typeOf input}";
      };

      simulation = [
        {
          args = {
            mode = "start";
            pattern = "foo";
            value = "foobar";
          };
          desired = true;
        }
        {
          args = {
            mode = "contains";
            pattern = "oob";
            value = "foobar";
          };
          desired = true;
        }
        {
          args = {
            mode = "end";
            pattern = "bar";
            value = "foobar";
          };
          desired = true;
        }
        {
          args = ["foobar" "foo" "start"];
          desired = true;
        }
        {
          args = ["foobar" "bar" "end"];
          desired = true;
        }
        {
          args = ["foobar" "xyz"];
          desired = false;
        }
        #> invalid mode throws
        {
          args = ["foobar" "foo" "sideways"];
          throws = true;
        }
      ];

      execution = args: let
        inherit (_defaults) modes;
        inherit (args) mode pattern value;

        valueLength = stringLength value;
        patternLength = stringLength pattern;
        # TODO: This needs to be lifted out, it is reusable. We should probable add the data part to _debaults
        escaped =
          replaceStrings
          ["\\" "." "+" "*" "?" "^" "$" "(" ")" "[" "]" "{" "}" "|"]
          ["\\\\" "\\." "\\+" "\\*" "\\?" "\\^" "\\$" "\\(" "\\)" "\\[" "\\]" "\\{" "\\}" "\\|"]
          pattern;
        containsPattern = ".*${escaped}.*";
      in
        if mode == modes.start
        then substring 0 patternLength value == pattern
        else if mode == modes.contains
        then match containsPattern value != null
        else let
          suffix = substring (valueLength - patternLength) patternLength value;
        in
          valueLength >= patternLength && suffix == pattern;
    };

  /**
  Test whether a string starts with a given prefix. A hybrid partial application
  of `has` with `mode` pre-bound to `"start"`.

  # Type
  ```nix
  hasPrefix :: AttrSet -> Bool
  hasPrefix :: String -> String -> Bool
  ```

  # Dependencies
  - assembly.mkFn
  - strings.has

  # Arguments
  value
  : The string to inspect, or a configuration attribute set { value, check }.

  check
  : The prefix string to check for.

  # Examples
  - __Explicit Attribute Set Configuration__

  > __hasPrefix__ { `check` = _"foo"_; `value` = _"foobar"_; }
  => true

  > __hasPrefix__ { `check` = _"bar"_; `value` = _"foobar"_; }
  => false

  - __Curried Positional (Value then Check)__

  > __hasPrefix__ _"foobar"_ _"foo"_
  => true

  - __Partial application__

  > hasPrefixOfFoobar = __hasPrefix__ _"foobar"_;
  > __hasPrefixOfFoobar__ _"foo"_
  => true

  > __hasPrefixOfFoobar__ _"bar"_
  => false
  */
  hasPrefix = let
    _name = "strings.hasPrefix";
    required = ["value" "check"];
    positional = required;
  in
    mkFn {
      name = _name;
      inherit required positional;

      validation = {
        check = input:
          if isString input
          then input
          else throw "${_name}: check must be a string, got ${typeOf input}";
        value = input:
          if isString input
          then input
          else throw "${_name}: value must be a string, got ${typeOf input}";
      };

      simulation = [
        {
          args = {
            check = "foo";
            value = "foobar";
          };
          desired = true;
        }
        {
          args = {
            check = "bar";
            value = "foobar";
          };
          desired = false;
        }
        {
          args = ["foobar" "foo"];
          desired = true;
        }
      ];

      execution = args:
        has {
          mode = "start";
          pattern = args.check;
          value = args.value;
        };
    };

  /**
  Test whether a string contains a given infix. A hybrid partial application
  of `has` with `mode` pre-bound to `"contains"`.

  # Type
  ```nix
  hasInfix :: AttrSet -> Bool
  hasInfix :: String -> String -> Bool
  ```

  # Dependencies
  - assembly.mkFn
  - strings.has

  # Arguments
  value
  : The string to inspect, or a configuration attribute set { value, check }.

  check
  : The infix string to check for.

  # Examples
  - __Explicit Attribute Set Configuration__

  > __hasInfix__ { `check` = _"oob"_; `value` = _"foobar"_; }
  => true

  > __hasInfix__ { `check` = _"xyz"_; `value` = _"foobar"_; }
  => false

  - __Curried Positional (Value then Check)__

  > __hasInfix__ _"foobar"_ _"oob"_
  => true

  - __Partial application__

  > hasInfixOfFoobar = __hasInfix__ _"foobar"_;
  > __hasInfixOfFoobar__ _"oob"_
  => true

  > __hasInfixOfFoobar__ _"xyz"_
  => false
  */
  hasInfix = let
    _name = "strings.hasInfix";
    required = ["value" "check"];
    positional = required;
  in
    mkFn {
      name = _name;
      inherit required positional;

      validation = {
        check = input:
          if isString input
          then input
          else throw "${_name}: check must be a string, got ${typeOf input}";
        value = input:
          if isString input
          then input
          else throw "${_name}: value must be a string, got ${typeOf input}";
      };

      simulation = [
        {
          args = {
            check = "oob";
            value = "foobar";
          };
          desired = true;
        }
        {
          args = {
            check = "xyz";
            value = "foobar";
          };
          desired = false;
        }
        {
          args = ["foobar" "oob"];
          desired = true;
        }
      ];

      execution = args:
        has {
          mode = "contains";
          pattern = args.check;
          value = args.value;
        };
    };

  /**
  Test whether a string ends with a given suffix. A hybrid partial application
  of `has` with `mode` pre-bound to `"end"`.

  # Type
  ```nix
  hasSuffix :: AttrSet -> Bool
  hasSuffix :: String -> String -> Bool
  ```

  # Dependencies
  - assembly.mkFn
  - strings.has

  # Arguments
  value
  : The string to inspect, or a configuration attribute set { value, check }.

  check
  : The suffix string to check for.

  # Examples
  - __Explicit Attribute Set Configuration__

  > __hasSuffix__ { `check` = _"bar"_; `value` = _"foobar"_; }
  => true

  > __hasSuffix__ { `check` = _"foo"_; `value` = _"foobar"_; }
  => false

  - __Curried Positional (Value then Check)__

  > __hasSuffix__ _"foobar"_ _"bar"_
  => true

  - __Partial application__

  > hasSuffixOfFoobar = __hasSuffix__ _"foobar"_;
  > __hasSuffixOfFoobar__ _"bar"_
  => true

  > __hasSuffixOfFoobar__ _"foo"_
  => false
  */
  hasSuffix = let
    _name = "strings.hasSuffix";
    required = ["check" "value"];
    positional = required;
  in
    mkFn {
      name = _name;
      inherit required positional;

      validation = {
        check = input:
          if isString input
          then input
          else throw "${_name}: check must be a string, got ${typeOf input}";
        value = input:
          if isString input
          then input
          else throw "${_name}: value must be a string, got ${typeOf input}";
      };

      simulation = [
        {
          args = {
            check = "bar";
            value = "foobar";
          };
          desired = true;
        }
        {
          args = {
            check = "foo";
            value = "foobar";
          };
          desired = false;
        }
        {
          args = ["foobar" "bar"];
          desired = true;
        }
      ];

      execution = args:
        has {
          mode = "end";
          pattern = args.check;
          value = args.value;
        };
    };

  /**
  Trim characters matching a pattern from a string, according to a mode:
  `"start"`, `"end"`, `"both"` (default), or `"all"` (global removal).

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (value, then pattern, then mode).

  # Type
  ```nix
  trim :: AttrSet -> String
  trim :: String -> String -> String -> String
  ```

  # Dependencies
  - assembly.mkFn
  - builtins.elem
  - builtins.match
  - builtins.split
  - builtins.isString
  - trivial.makeHybrid
  - trivial.readHybrid
  - strings.concat

  # Arguments
  value
  : The non-empty string to trim, or a configuration attribute set containing
  { `value`, `pattern` ?, `mode` ? }.

  pattern
  : A non-empty regular expression matching the characters to remove. Defaults
  to `"[[:space:]]"`.

  mode
  : The trimming mode. One of `"start"`, `"end"`, `"both"`, `"every"`,
  `"all"`, or `"each"`. `"all"` aliases `"every"`, `"each"` aliases
  `"both"`, and the default is `"both"`.

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
  in
    mkFn {
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
  trimSpecialized = name: mode: let
    desired = {
      start = "foo bar ";
      end = " foo bar";
      both = "foo bar";
      all = "foobar";
    };
  in
    mkFn {
      name = "strings.${name}";
      positional = ["value" "pattern"];
      required = ["value"];
      defaults.pattern = "[[:space:]]";
      simulation = [
        {
          args = " foo bar ";
          desired = desired.${mode};
        }
        {
          args = ["--foo-bar--" "-"];
          desired =
            if mode == "start"
            then "foo-bar--"
            else if mode == "end"
            then "--foo-bar"
            else "foo-bar";
        }
        {
          args = {value = " foo bar ";};
          desired = desired.${mode};
        }
      ];
      execution = args:
        trim {
          inherit (args) value pattern;
          inherit mode;
        };
    };

  /**
  Trim repeated matches from the start of a string. This is the `"start"`
  specialization of `trim`; the pattern is a POSIX extended regular expression
  and defaults to whitespace.

  # Type
  ```nix
  trimStart :: AttrSet -> String
  trimStart :: String -> String -> String
  ```

  # Dependencies
  - assembly.mkFn
  - strings.trim

  # Arguments
  value
  : The non-empty string to trim, or `{ value, pattern ? "[[:space:]]" }`.

  pattern
  : A non-empty POSIX extended regular expression. In positional calls it
    follows `value`, and may be omitted to trim whitespace.

  # Examples
  > trimStart "  hello  "
  => "hello  "

  > trimStart "--hello--" "-"
  => "hello--"

  > trimStart { value = "0042"; pattern = "0"; }
  => "42"
  */
  trimStart = trimSpecialized "trimStart" "start";

  /**
  Trim repeated matches from the end of a string. This is the `"end"`
  specialization of `trim`; the pattern is a POSIX extended regular expression
  and defaults to whitespace.

  # Type
  ```nix
  trimEnd :: AttrSet -> String
  trimEnd :: String -> String -> String
  ```

  # Dependencies
  - assembly.mkFn
  - strings.trim

  # Arguments
  value
  : The non-empty string to trim, or `{ value, pattern ? "[[:space:]]" }`.

  pattern
  : A non-empty POSIX extended regular expression. In positional calls it
    follows `value`, and may be omitted to trim whitespace.

  # Examples
  > trimEnd "  hello  "
  => "  hello"

  > trimEnd "--hello--" "-"
  => "--hello"

  > trimEnd { value = "4200"; pattern = "0"; }
  => "42"
  */
  trimEnd = trimSpecialized "trimEnd" "end";

  /**
  Trim repeated matches from both ends of a string while preserving matches in
  its interior. This is the `"both"` specialization of `trim`; the pattern is
  a POSIX extended regular expression and defaults to whitespace.

  # Type
  ```nix
  trimEnds :: AttrSet -> String
  trimEnds :: String -> String -> String
  ```

  # Dependencies
  - assembly.mkFn
  - strings.trim

  # Arguments
  value
  : The non-empty string to trim, or `{ value, pattern ? "[[:space:]]" }`.

  pattern
  : A non-empty POSIX extended regular expression. In positional calls it
    follows `value`, and may be omitted to trim whitespace.

  # Examples
  > __trimEnds__ _"  hello  "_
  => "hello"

  > __trimEnds_ _"--hello-world--"_ _"-"_
  => "hello-world"

  > trimEnds { value = "00-42-00"; pattern = "0"; }
  => "-42-"
  */
  trimEnds = trimSpecialized "trimEnds" "both";

  /**
  Remove every match from a string, including matches between other
  characters. This is the `"all"` specialization of `trim`; the pattern is a
  POSIX extended regular expression and defaults to whitespace.

  # Type
  ```nix
  trimAll :: AttrSet -> String
  trimAll :: String -> String -> String
  ```

  # Dependencies
  - assembly.mkFn
  - strings.trim

  # Arguments
  value
  : The non-empty string to trim, or `{ value, pattern ? "[[:space:]]" }`.

  pattern
  : A non-empty POSIX extended regular expression. In positional calls it
    follows `value`, and may be omitted to remove whitespace.

  # Examples
  > trimAll " foo bar "
  => "foobar"

  > trimAll "-foo-bar-" "-"
  => "foobar"

  > trimAll { value = "a1b2c3"; pattern = "[0-9]"; }
  => "abc"
  */
  trimAll = trimSpecialized "trimAll" "all";

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
  - assembly.mkFn
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
  split = mkFn {
    name = "strings.split";
    positional = ["sep" "str"];
    required = ["sep" "str"];

    validation = {};

    simulation = [
      {
        args = {
          sep = ".";
          str = "a.b.c";
        };
        desired = ["a" "b" "c"];
      }
      {
        args = ["/" "usr/local/bin"];
        desired = ["usr" "local" "bin"];
      }
      {
        args = ["," "a,b,,c"];
        desired = ["a" "b" "" "c"];
      }
      {
        args = ["." "a.b.c"];
        desired = ["a" "b" "c"];
      }
      {
        args = ["." "no-dots-here"];
        desired = ["no-dots-here"];
      }
    ];

    execution = args: let
      #> List of all POSIX ERE special characters
      specialChars = ["\\" "." "+" "*" "?" "^" "$" "(" ")" "[" "]" "{" "}" "|"];

      #> Their escaped counterparts
      escapedChars = map (c: "\\${c}") specialChars;

      #> Safely escape the separator so it acts as a literal string, not a regex
      escapedSep = replaceStrings specialChars escapedChars args.sep;

      #> Perform the split using the built-in regex split, then filter out
      #> the regex match lists, keeping only the string segments
      rawSplit = splitOrig escapedSep args.str;
    in
      filter isString rawSplit;
  };

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
