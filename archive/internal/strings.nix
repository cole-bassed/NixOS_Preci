{
  debug,
  lists,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit
        _applyStr
        _normalizeSymbols
        _splitWords
        capitalize
        indent
        normalize
        orDefault
        orEmpty
        orNull
        replaceAll
        toCamel
        toLower'
        toPascal
        toScreamingSnake
        toSnake
        toTitle
        toUpper'
        trim'
        trimEnd
        trimStart
        wrap
        ;
      trim = trim';
      isEmpty = isEmpty';
      isNotEmpty = isNotEmpty';
    };
    global = {
      inherit
        capitalize
        indent
        normalize
        replaceAll
        toCamel
        toLower'
        toPascal
        toScreamingSnake
        toSnake
        toTitle
        toUpper'
        trim'
        trimEnd
        trimStart
        wrap
        ;
      capitalizeString = capitalize;
      isEmptyString = isEmpty';
      isNotEmptyString = isNotEmpty';
      normalizeString = normalize;
      orDefaultString = orDefault;
      orEmptyString = orEmpty;
      orNullString = orNull;
      quote = wrap;
      quoteString = wrap;
      replaceAllStrings = replaceAll;
      toCamelCase = toCamel;
      toLowerCase = toLower';
      toPascalCase = toPascal;
      toScreamingSnakeCase = toScreamingSnake;
      toSnakeCase = toSnake;
      toTitleCase = toTitle;
      toUpperCase = toUpper';
      trimString = trim';
      trimStringEnd = trimEnd;
      trimStringStart = trimStart;
    };
  };

  inherit (lists) head tail genList asList any;
  inherit (debug) withContext;
  inherit (types) isEmpty isNotEmpty isList isAttrs isString typeOf;
  inherit (strings) concatStrings concatStringsSep hasPrefix hasSuffix optionalString removePrefix removeSuffix replaceStrings splitString stringLength substring toLower toUpper;

  isEmpty' = value: value == "";
  isNotEmpty' = value: !isEmpty' value;

  orNull = value:
    assert withContext {
      name = "strings.orNull";
      assertion = isEmpty value || isString value;
      message = "expected a string, got ${typeOf value}";
      context = "evaluating strings.orNull";
    };
      if isEmpty value || !(isString value)
      then null
      else value;

  orDefault = default: value:
    assert withContext {
      name = "strings.orDefault";
      assertion = isString default && isString value;
      message = "expected strings, got default=${typeOf default} value=${typeOf value}";
      context = "evaluating strings.orDefault";
    };
      if isNotEmpty' value
      then value
      else default;

  orEmpty = value:
    assert withContext {
      name = "strings.orEmpty";
      assertion = value == null || isString value;
      message = "expected a string or null, got ${typeOf value}";
      context = "evaluating strings.orEmpty";
    };
      optionalString (isNotEmpty' value) value;

  # Internal: apply a string transform to a string or each item in a list.
  _applyStr = fn: input:
    if isList input
    then map fn input
    else fn input;

  # Internal: split a string into lowercase words on spaces, underscores, hyphens.
  _splitWords = text:
    splitString "-" (
      replaceStrings [" " "_"] ["-" "-"]
      (_normalizeSymbols (toLower text))
    );

  _symbolAliases = {
    "c++" = "cpp";
    "c#" = "csharp";
    ".net" = "dotnet";
    "objc" = "objectivec";
  };

  _normalizeSymbols = text:
    _symbolAliases.${text} or (replaceStrings ["++" "#" "."] ["p" "sharp" "-"] text);

  /**
  Convert a string or list of strings to lower case.
  */
  toLower' = input:
    assert withContext {
      name = "strings.toLower'";
      assertion = !(isList input && any isList input);
      message = "nested lists are not supported";
      context = "evaluating toLower'";
    };
      _applyStr toLower input;

  /**
  Convert a string or list of strings to upper case.
  */
  toUpper' = input:
    assert withContext {
      name = "strings.toUpper'";
      assertion = !(isList input && any isList input);
      message = "nested lists are not supported";
      context = "evaluating toUpper'";
    };
      _applyStr toUpper input;

  /**
  Remove leading occurrences of `chars` from a string or list of strings.
  Pass null to default to a single space. Strips repeatedly.
  */
  trimStart = chars: let
    char =
      if chars == null
      then " "
      else if !isString chars
      then throw "trimStart: chars must be a string or null"
      else chars;
    asStr = text:
      if hasPrefix char text
      then asStr (removePrefix char text)
      else text;
  in
    input:
      assert withContext {
        name = "strings.trimStart";
        assertion = !(isList input && any isList input);
        message = "nested lists are not supported";
        context = "evaluating trimStart";
      };
        _applyStr asStr input;

  /**
  Remove trailing occurrences of `chars` from a string or list of strings.
  Pass null to default to a single space. Strips repeatedly.
  */
  trimEnd = chars: let
    char =
      if chars == null
      then " "
      else if !isString chars
      then throw "trimEnd: chars must be a string or null"
      else chars;
    asStr = text:
      if hasSuffix char text
      then asStr (removeSuffix char text)
      else text;
  in
    input:
      assert withContext {
        name = "strings.trimEnd";
        assertion = !(isList input && any isList input);
        message = "nested lists are not supported";
        context = "evaluating trimEnd";
      };
        _applyStr asStr input;

  /**
  Remove leading and trailing occurrences of `chars` from a string or list of strings.
  Pass null to default to a single space.
  */
  trim' = chars: input: trimStart chars (trimEnd chars input);

  /**
  Replace all occurrences of substrings in a string or list of strings.
  Accepts either a single search/replace pair, or parallel lists.
  */
  replaceAll = search: replace: let
    ss = asList search;
    rs = asList replace;
  in
    input:
      assert withContext {
        name = "strings.replaceAll";
        assertion = !(isList input && any isList input);
        message = "nested lists are not supported in input";
        context = "evaluating replaceAll";
      };
        _applyStr (replaceStrings ss rs) input;

  /**
  Normalize a string or list of strings for fuzzy matching.
  Converts to lower case and replaces spaces/underscores with hyphens.
  */
  normalize = input:
    if isEmpty input
    then null
    else
      assert withContext {
        name = "strings.normalize";
        assertion = !(isList input && any isList input);
        message = "nested lists are not supported";
        context = "evaluating normalize";
      };
        _applyStr (text: replaceStrings [" " "_"] ["-" "-"] (toLower text)) input;

  indent = n: concatStringsSep "" (genList (_: " ") n);

  /**
  Capitalize the first character of a string or list of strings.
  */
  capitalize = input: let
    asStr = text:
      if text == ""
      then ""
      else toUpper (substring 0 1 text) + substring 1 (stringLength text) text;
  in
    assert withContext {
      name = "strings.capitalize";
      assertion = !(isList input && any isList input);
      message = "nested lists are not supported";
      context = "evaluating capitalize";
    };
      _applyStr asStr input;

  /**
  Convert a string or list of strings to camelCase.
  */
  toCamel = input: let
    asStr = text: let
      words = _splitWords text;
    in
      head words + concatStringsSep "" (map capitalize (tail words));
  in
    assert withContext {
      name = "strings.toCamel";
      assertion = !(isList input && any isList input);
      message = "nested lists are not supported";
      context = "evaluating toCamel";
    };
      if isList input
      then concatStringsSep "" ([head input] ++ map capitalize (tail input))
      else asStr input;

  /**
  Convert a string or list of strings to PascalCase.
  */
  toPascal = input: let
    asStr = text: concatStringsSep "" (map capitalize (_splitWords text));
  in
    assert withContext {
      name = "strings.toPascal";
      assertion = !(isList input && any isList input);
      message = "nested lists are not supported";
      context = "evaluating toPascal";
    };
      if isList input
      then concatStringsSep "" (map capitalize input)
      else asStr input;

  /**
  Convert a string or list of strings to snake_case.
  */
  toSnake = input: let
    asStr = text: concatStringsSep "_" (_splitWords text);
  in
    assert withContext {
      name = "strings.toSnake";
      assertion = !(isList input && any isList input);
      message = "nested lists are not supported";
      context = "evaluating toSnake";
    };
      if isList input
      then concatStringsSep "_" input
      else asStr input;

  /**
  Convert a string or list of strings to SCREAMING_SNAKE_CASE.
  */
  toScreamingSnake = input: let
    asStr = text: toUpper (concatStringsSep "_" (_splitWords text));
  in
    assert withContext {
      name = "strings.toScreamingSnake";
      assertion = !(isList input && any isList input);
      message = "nested lists are not supported";
      context = "evaluating toScreamingSnake";
    };
      if isList input
      then toUpper (concatStringsSep "_" input)
      else asStr input;

  /**
  Convert a string or list of strings to Title Case.
  */
  toTitle = input: let
    asStr = text: concatStringsSep " " (map capitalize (_splitWords text));
  in
    assert withContext {
      name = "strings.toTitle";
      assertion = !(isList input && any isList input);
      message = "nested lists are not supported";
      context = "evaluating toTitle";
    };
      if isList input
      then concatStringsSep " " (map capitalize input)
      else asStr input;

  /**
  Wrap string(s) in a token (default backtick).
  */
  wrap = value: let
    args =
      if isAttrs value
      then
        if value ? input
        then value
        else if value ? text
        then value // {input = value.text;}
        else
          assert withContext {
            name = "strings.wrap";
            assertion = false;
            message = "expected attrset to have an `input` or `text` key";
            context = "evaluating wrap input";
          }; null
      else if isList value || isString value
      then {input = value;}
      else
        assert withContext {
          name = "strings.wrap";
          assertion = false;
          message = "expected `value` to be a string, list, or attrset";
          context = "evaluating wrap value";
        }; null;

    input = assert withContext {
      name = "strings.wrap";
      assertion = isNotEmpty args.input;
      message = "expected `input` to be a non-null value or a non-empty list";
      context = "evaluating wrap input";
    };
      args.input;

    token = let
      token' = args.token or "`";
    in
      assert withContext {
        name = "strings.wrap";
        assertion = isString token' && token' != "";
        message = "expected `token` to be a non-empty string";
        context = "evaluating wrap token";
      }; token';

    delimiter = let
      sep = args.delimiter or (args.sep or (optionalString (isList args.input) " or "));
    in
      assert withContext {
        name = "strings.wrap";
        assertion = isString sep;
        message = "expected `delimiter` to be a string";
        context = "evaluating wrap delimiter";
      }; sep;

    rendered = map (item: concatStrings [token (toString item) token]) (asList input);
  in
    if isList input
    then concatStringsSep delimiter rendered
    else head rendered;
in
  exports
