{
  strings,
  trivial,
  lists,
  ...
}: let
  exports = {
    scoped = {
      inherit
        coalesce
        orDefault
        orDefaultIf
        isEmpty
        isNotEmpty
        ;

      inherit
        (builtins)
        isAttrs
        isFunction
        isList
        isPath
        isString
        typeOf
        ;

      type = typeOf;

      from = with builtins; {
        json = fromJSON;
        toml = fromTOML;
      };

      to = with builtins; {
        json = toJSON;
        xml = toXML;
        file = toFile;
        string = toString;
        path = toPath;
      };
    };

    global = {
      inherit
        coalesce
        orDefault
        isEmpty
        isNotEmpty
        ;

      inherit
        (builtins)
        fromJSON
        fromTOML
        toFile
        toJSON
        toPath
        toString
        toXML
        ;
    };
  };

  inherit (builtins) isString stringLength typeOf;
  inherit (strings) trim';
  inherit (lists) lastOf;
  inherit (trivial) makeHybrid readHybrid;

  defaults.types = {
    bool = false;
    float = 0.0;
    int = 0;
    lambda = _: null;
    list = [];
    null = null;
    path = /.;
    set = {};
    string = "";
  };

  /**
  Check whether a value is considered empty for defaulting purposes.

  # Emptiness Rules

  - `null` is empty.
  - Strings are empty when blank or whitespace-only.
  - Lists are empty when equal to `[]`.
  - Attribute sets are empty when equal to `{}`.
  - Numbers, booleans, and paths are never empty.
  - Functions are unsupported and produce an error.

  # Type
  ```nix
  isEmpty :: a -> Bool
  ````

  # Dependencies

  - strings.trim
  - builtins.isAttrs
  - builtins.isFunction
  - builtins.isList
  - builtins.isString
  - builtins.stringLength

  # Arguments

  value
  : The value to test.

  # Examples

  > isEmpty null
  => true

  > isEmpty "   "
  => true

  > isEmpty {}
  => true

  > isEmpty [ 1 ]
  => false

  > isEmpty 0
  => false
  */
  isEmpty = value: let
    type = typeOf value;
  in
    if type == "lambda"
    then throw "isEmpty: functions are not supported"
    else if type == "null"
    then true
    else if type == "string"
    then stringLength (trim' value) == 0
    else if type == "list" || type == "set"
    then value == defaults.types.${type}
    else false;
  /**
  Check whether a value is not empty according to `isEmpty`.

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
  > isNotEmpty "hello"
  => true

  > isNotEmpty 0
  => true

  > isNotEmpty false
  => true

  > isNotEmpty null
  => false

  > isNotEmpty ""
  => false

  > isNotEmpty []
  => false
  */
  isNotEmpty = value: !isEmpty value;

  /**
  Return the first value when it is not `null`; otherwise return the fallback.

  Unlike `orFallback`, this function only treats `null` as absent. Empty strings,
  lists, and attribute sets are returned unchanged.

  # Type
  ```nix
  coalesce :: a -> a -> a
  ```

  # Arguments
  value
  : The preferred value.

  fallback
  : The value returned when `value` is `null`.

  # Examples
  > coalesce "hello" "fallback"
  => "hello"

  > coalesce "" "fallback"
  => ""

  > coalesce null "fallback"
  => "fallback"
  */
  coalesce = value: default:
    orDefaultIf {
      condition = value != null;
      inherit default value;
    };

  /**
  Return a value when it has the requested Nix type; otherwise return that
  type's registered default value.

  Supports an explicit configuration attribute set or a curried positional
  invocation using the type name followed by the value.

  # Type

  ```nix
  orDefault :: AttrSet -> a
  orDefault :: String -> a -> a
  ```

  # Supported Type Names
  * `"bool"`
  * `"float"`
  * `"int"`
  * `"lambda"`
  * `"list"`
  * `"null"`
  * `"path"`
  * `"set"`
  * `"string"`

  # Dependencies

  * builtins.typeOf
  * trivial.makeHybrid
  * trivial.readHybrid

  # Arguments

  arg
  : A configuration attribute set `{ type, value }` or the first positional
  argument representing the requested type.

  # Examples

  * __Curried positional invocation__

  > orDefault "list" [ "value" ]
  => [ "value" ]

  > orDefault "list" "value"
  => []

  > orDefault "string" null
  => ""

  * __Explicit attribute-set invocation__

  > orDefault {
  > type = "set";
  > value = [ "value" ];
  > }
  => {}

  * __Partial application__

  > listOrDefault = orDefault "list";

  > listOrDefault "value"
  => []

  > listOrDefault [ "value" ]
  => [ "value" ]
  */
  orDefault = arg: let
    positional = ["default" "value"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = ["value"];
          allowed = positional ++ ["type"];
        };

        hasDefault = args ? default;
        hasType = args ? type;

        check =
          if hasDefault && hasType
          then throw "orDefault: provide either 'default' or 'type', not both"
          else if !hasDefault && !hasType
          then throw "orDefault: provide either 'default' or 'type'"
          else true;

        default =
          if hasDefault
          then args.default
          else defaults.types.${args.type}
          or (throw "orDefault: Unknown type kind '${args.type}'");
      in
        assert check;
          orDefaultIf {
            condition = isNotEmpty args.value;
            inherit default;
            inherit (args) value;
          }
    );
  in
    function arg;

  /**
  Return a value when a condition is true; otherwise return the registered
  default for the requested type.

  This generalizes `optionalAttrs` and `optionals` by selecting the empty/default
  value from `defaults.types`.

  # Type

  ```nix
  orDefaultIf :: AttrSet -> a
  orDefaultIf :: Bool -> String -> a -> a
  ```

  # Arguments
  condition
  : A boolean controlling whether value is retained.

  type
  : The registered Nix type whose default should be returned.

  value
  : The value to test.

  # Examples

  - __Replacement for `optionalAttrs`__

  > orDefaultIf true "set" { enable = true; }
  => { enable = true; }

  > orDefaultIf false "set" { enable = true; }
  => {}

  _Equivalent to:_

  > optionalAttrs true { enable = true; }
  => { enable = true; }

  > optionalAttrs false { enable = true; }
  => {}

  __Replacement for `optionals`__

  > orDefaultIf true "list" [ "git" "curl" ]
  => [ "git" "curl" ]

  > orDefaultIf false "list" [ "git" "curl" ]
  => []

  Equivalent to:

  > optionals true [ "git" "curl" ]
  => [ "git" "curl" ]

  > optionals false [ "git" "curl" ]
  => []

  __Replacement for `optionalString`__

  > orDefaultIf true "string" "enabled"
  => "enabled"

  > orDefaultIf false "string" "enabled"
  => ""

  Equivalent to:

  > optionals true [ "git" "curl" ]
  => [ "git" "curl" ]

  > optionals false [ "git" "curl" ]
  => []
  */
  orDefaultIf = arg: let
    _name = "orDefaultIf";
    positional = ["condition" "fallback" "value"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = ["condition" "value"];
          allowed = positional ++ ["type" "default"];
        };

        hasType = args ? type;
        hasDefault = args ? default;
        hasFallback = args ? fallback;

        check =
          if typeOf args.condition != "bool"
          then throw "${_name}: condition must be a bool"
          else if hasType && hasDefault
          then throw "${_name}: provide either 'type' or 'default', not both"
          else true;

        fallback =
          if hasDefault
          then args.default
          else if hasType
          then
            if !isString args.type
            then throw "${_name}: type must be a string"
            else defaults.types.${args.type}
            or (throw "${_name}: Unknown type kind '${args.type}'")
          else if hasFallback && isString args.fallback && defaults.types ? ${args.fallback}
          then defaults.types.${args.fallback}
          else if hasFallback
          then args.fallback
          else defaults.types.${typeOf args.value};
      in
        assert check;
          if args.condition
          then args.value
          else fallback
    );
  in
    function arg;
in
  exports
