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
  inherit (lists) asList;
  inherit (trivial) buildFunction;

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

  /**
  Concatenate a list of strings with an optional delimiter, safely filtering out null values.

  # Type
  ```nix
  concat :: AttrSet -> String
  concat :: String -> List String -> String
  concat :: List String -> String
  ```
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

  /**
  Test whether a string satisfies a positional match against a check string,
  according to a mode: `"start"` (prefix), `"contains"` (infix), or `"end"` (suffix).

  # Type
  ```nix
  has :: AttrSet -> Bool
  has :: String -> String -> String -> Bool
  ```
  */
  has = buildFunction {
    name = "strings.has";
    positional = ["mode" "check" "value"];
    required = ["mode" "check" "value"];

    validation = {
      mode = {
        validate = input:
          if !isString input
          then throw "strings.has: mode must be a string, got ${typeOf input}"
          else if !elem input _defaults.modes.names
          then throw "strings.has: mode must be one of ${concat ", " (map quote _defaults.modes.names)}"
          else input;
        options = _defaults.modes.names;
        type = "enum";
      };
      check = input:
        if isString input
        then input
        else throw "strings.has: check must be a string, got ${typeOf input}";
      value = input:
        if isString input
        then input
        else throw "strings.has: value must be a string, got ${typeOf input}";
    };

    simulation = [
      {
        args = {
          mode = "start";
          check = "foo";
          value = "foobar";
        };
        desired = true;
      }
      {
        args = {
          mode = "contains";
          check = "oob";
          value = "foobar";
        };
        desired = true;
      }
      {
        args = {
          mode = "end";
          check = "bar";
          value = "foobar";
        };
        desired = true;
      }
      {
        args = ["start" "foo" "foobar"];
        desired = true;
      }
      {
        args = ["end" "bar" "foobar"];
        desired = true;
      }
      {
        args = ["contains" "xyz" "foobar"];
        desired = false;
      }
      #> invalid mode throws
      {
        args = ["sideways" "foo" "foobar"];
        throws = true;
      }
    ];

    execution = args: let
      inherit (_defaults) modes;
      inherit (args) mode check value;

      valueLength = stringLength value;
      checkLength = stringLength check;
      escaped =
        replaceStrings
        ["\\" "." "+" "*" "?" "^" "$" "(" ")" "[" "]" "{" "}" "|"]
        ["\\\\" "\\." "\\+" "\\*" "\\?" "\\^" "\\$" "\\(" "\\)" "\\[" "\\]" "\\{" "\\}" "\\|"]
        check;
      containsPattern = ".*${escaped}.*";
    in
      if mode == modes.start
      then substring 0 checkLength value == check
      else if mode == modes.contains
      then match containsPattern value != null
      else let
        suffix = substring (valueLength - checkLength) checkLength value;
      in
        valueLength >= checkLength && suffix == check;
  };

  /**
  Test whether a string starts with a given prefix. A hybrid partial application
  of `has` with `mode` pre-bound to `"start"`.

  # Type
  ```nix
  hasPrefix :: AttrSet -> Bool
  hasPrefix :: String -> String -> Bool
  ```
  */
  hasPrefix = buildFunction {
    name = "strings.hasPrefix";
    positional = ["check" "value"];
    required = ["check" "value"];

    validation = {};

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
        args = ["foo" "foobar"];
        desired = true;
      }
    ];

    execution = args: has "start" args.check args.value;
  };

  /**
  Test whether a string contains a given infix. A hybrid partial application
  of `has` with `mode` pre-bound to `"contains"`.

  # Type
  ```nix
  hasInfix :: AttrSet -> Bool
  hasInfix :: String -> String -> Bool
  ```
  */
  hasInfix = buildFunction {
    name = "strings.hasInfix";
    positional = ["check" "value"];
    required = ["check" "value"];

    validation = {};

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
        args = ["oob" "foobar"];
        desired = true;
      }
    ];

    execution = args: has "contains" args.check args.value;
  };

  /**
  Test whether a string ends with a given suffix. A hybrid partial application
  of `has` with `mode` pre-bound to `"end"`.

  # Type
  ```nix
  hasSuffix :: AttrSet -> Bool
  hasSuffix :: String -> String -> Bool
  ```
  */
  hasSuffix = buildFunction {
    name = "strings.hasSuffix";
    positional = ["check" "value"];
    required = ["check" "value"];

    validation = {};

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
        args = ["bar" "foobar"];
        desired = true;
      }
    ];

    execution = args: has "end" args.check args.value;
  };

  /**
  Trim characters matching a pattern from a string, according to a mode:
  `"start"`, `"end"`, `"both"` (default), or `"all"` (global removal).

  # Type
  ```nix
  trim :: AttrSet -> String
  trim :: String -> String -> String -> String
  ```
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
        {
          args = "   hello   ";
          desired = "hello";
        }
        {
          args = ["hello" "l"];
          desired = "hello";
        }
        {
          args = ["hello" "l" "every"];
          desired = "heo";
        }
        {
          args = ["hello" "l" "all"];
          desired = "heo";
        }
        {
          args = ["   hello   " "[[:space:]]" "each"];
          desired = "hello";
        }
        {
          args = ["   hello   " "[[:space:]]" "start"];
          desired = "hello   ";
        }
        {
          args = ["   hello   " "[[:space:]]" "end"];
          desired = "   hello";
        }
        {
          args = {value = "   hello   ";};
          desired = "hello";
        }
        {
          args = {
            value = "hello";
            pattern = "l";
          };
          desired = "hello";
        }
        {
          args = {
            value = "hello";
            pattern = "l";
            mode = "every";
          };
          desired = "heo";
        }
        {
          args = ["hello" "l" ""];
          throws = true;
        }
        {
          args = ["hello" "l" "not-a-mode"];
          throws = true;
        }
        {
          args = {value = "";};
          throws = true;
        }
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

  /**
  Splits a string by a literal string separator.

  # Type
  ```nix
  split' :: AttrSet -> List String
  split' :: String -> String -> List String
  ```
  */
  split' = buildFunction {
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
      rawSplit = split escapedSep args.str;
    in
      filter isString rawSplit;
  };

  trimStart = buildFunction {
    name = "strings.trimStart";
    positional = ["pattern" "value"];
    required = ["value"];
    optional = ["pattern"];
    defaults = {pattern = "[[:space:]]";};

    validation = {};

    simulation = [
      {
        args = {value = "  hello";};
        desired = "hello";
      }
      {
        args = {
          pattern = "-";
          value = "--hello";
        };
        desired = "hello";
      }
      {
        args = ["-" "--hello"];
        desired = "hello";
      }
    ];

    execution = args: trim' "start" args.pattern args.value;
  };

  /**
  Trim characters matching a pattern from the end of a string. A hybrid
  partial application of `trim` with `mode` pre-bound to `"end"`.

  # Type
  ```nix
  trimEnd :: AttrSet -> String
  trimEnd :: String -> String -> String
  ```
  */
  trimEnd = buildFunction {
    name = "strings.trimEnd";
    positional = ["pattern" "value"];
    required = ["value"];
    optional = ["pattern"];
    defaults = {pattern = "[[:space:]]";};

    validation = {};

    simulation = [
      {
        args = {value = "hello  ";};
        desired = "hello";
      }
      {
        args = {
          pattern = "-";
          value = "hello--";
        };
        desired = "hello";
      }
      {
        args = ["-" "hello--"];
        desired = "hello";
      }
    ];

    execution = args: trim' "end" args.pattern args.value;
  };

  /**
  Trim characters matching a pattern from both ends of a string. A hybrid
  partial application of `trim` with `mode` pre-bound to `"both"`.

  # Type
  ```nix
  trimBoth :: AttrSet -> String
  trimBoth :: String -> String -> String
  ```
  */
  trimBoth = buildFunction {
    name = "strings.trimBoth";
    positional = ["pattern" "value"];
    required = ["value"];
    optional = ["pattern"];
    defaults = {pattern = "[[:space:]]";};

    validation = {};

    simulation = [
      {
        args = {value = "  hello  ";};
        desired = "hello";
      }
      {
        args = {
          pattern = "-";
          value = "--hello--";
        };
        desired = "hello";
      }
      {
        args = ["-" "--hello--"];
        desired = "hello";
      }
    ];

    execution = args: trim' "both" args.pattern args.value;
  };

  /**
  Trim all occurrences of a pattern from anywhere within a string. A hybrid
  partial application of `trim` with `mode` pre-bound to `"all"`.

  # Type
  ```nix
  trimAll :: AttrSet -> String
  trimAll :: String -> String -> String
  ```
  */
  trimAll = buildFunction {
    name = "strings.trimAll";
    positional = ["pattern" "value"];
    required = ["value"];
    optional = ["pattern"];
    defaults = {pattern = "[[:space:]]";};

    validation = {};

    simulation = [
      {
        args = {
          pattern = "-";
          value = "-foo-bar-";
        };
        desired = "foobar";
      }
      {
        args = {value = "foo bar   baz";};
        desired = "foobarbaz";
      }
      {
        args = ["-" "-foo-bar-"];
        desired = "foobar";
      }
    ];

    execution = args: trim' "all" args.pattern args.value;
  };

  /**
  Return a non-empty string as-is, otherwise return `""`.
  Strings containing only whitespace are treated as empty.

  # Type
  ```nix
  orEmpty :: a -> String
  ```
  */
  orEmpty = value:
    if isString value && stringLength (trim' value) > 0
    then value
    else "";

  quote = value: let
    quoteOne = item:
      "\""
      + replaceStrings ["\\" "\""] ["\\\\" "\\\""] (toString item)
      + "\"";
  in
    if isList value
    then "[ " + concatStringsSep " " (map quoteOne value) + " ]"
    else quoteOne value;
in
  exports
