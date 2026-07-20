{
  strings,
  attrsets,
  trivial,
  lists,
  ...
}: let
  exports = {
    scoped =
      {
        inherit
          coalesce
          orDefault
          orDefaultIf
          isEmpty
          isNotEmpty
          registry
          isFunction'
          ;

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
      }
      // registry;

    global = {
      typesRegistry = registry;
      inherit coalesce orDefault orDefaultIf isEmpty isNotEmpty;
      inherit
        (builtins)
        fromJSON
        isFunction
        fromTOML
        toFile
        toJSON
        toPath
        toString
        toXML
        ;
    };
  };

  inherit
    (builtins)
    attrNames
    isAttrs
    isBool
    isFloat
    isFunction
    isInt
    isList
    isPath
    isString
    mapAttrs
    stringLength
    typeOf
    ;
  inherit (attrsets) recursiveUpdate;
  inherit (lists) all lastOf;
  inherit (strings) trim';
  inherit (trivial) makeHybrid readHybrid;

  registry = let
    schema = {
      bool = {
        default = false;
        is = isBool;
      };
      float = {
        default = 0.0;
        is = isFloat;
      };
      int = {
        default = 0;
        is = isInt;
      };
      lambda = {
        default = x: x;
        is = isFunction;
      };
      list = {
        default = [];
        is = isList;
      };
      null = {
        default = null;
        is = isNull;
      };
      path = {
        default = ./.;
        is = isPath;
      };
      set = {
        default = {};
        is = isAttrs;
      };
      string = {
        default = "";
        is = isString;
      };
    };
    defaults = mapAttrs (name: val: val.default) schema;
    mkMock = overrides: recursiveUpdate defaults overrides;
    validate = config:
      all (
        name:
          schema.${name}.is
          config.${name}
      )
      (attrNames config);
  in {inherit schema defaults typeOf mkMock validate;};
  inherit (registry) defaults;

  /**
  Strict check for callables, safely handling standard primitive functions
  and Nix attribute set functors without accidentally evaluating them.
  */
  isFunction' = value:
    isFunction value || (isAttrs value && value ? __functor && isFunction value.__functor);

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
    then value == defaults.${type}
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

  Unlike `orDefault`, this function only treats `null` as absent. Empty strings,
  lists, and attribute sets are returned unchanged.

  Supports the standard hybrid invocation patterns: an explicit configuration
  attribute set, or curried positional arguments (value, then default).

  # Type
  ```nix
  coalesce :: AttrSet -> a
  coalesce :: a -> a -> a
  ```

  # Dependencies
  - trivial.makeHybrid
  - trivial.readHybrid
  - types.orDefaultIf

  # Arguments
  arg
  : A configuration attribute set { value, default }, or the preferred value
  for curried positional invocation.

  # Examples
  - __Pattern 1__: _Explicit Attribute Set Configuration_

  > coalesce { value = "hello"; default = "fallback"; }
  => "hello"

  > coalesce { value = null; default = "fallback"; }
  => "fallback"

  - __Pattern 2__: _Curried Positional (Value then Default)_

  > coalesce "" "fallback"
  => ""

  > coalesce null "fallback"
  => "fallback"

  > coalesce [] [ "a" ]
  => []

  - __Partial application__ (currying binds `value` first, then `default`)

  > nullOrFallback = coalesce null;
  > nullOrFallback "anonymous"
  => "anonymous"

  > helloOrFallback = coalesce "hello";
  > helloOrFallback "anonymous"
  => "hello"
  */
  coalesce = arg: let
    positional = ["value" "default"];
    primary = lastOf positional;

    function = makeHybrid {inherit positional primary;} (
      payload: let
        args = readHybrid {
          inherit payload;
          required = positional;
        };
      in
        orDefaultIf {
          condition = args.value != null;
          inherit (args) default value;
        }
    );
  in
    function arg;

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
  default
  : The fallback value. In positional invocations, a registered type name is
  resolved to that type's default value.

  type
  : The registered Nix type whose default should be returned. Used only in
  explicit attribute-set invocations.

  value
  : The value to return when it is not empty.

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
          else defaults.${args.type}
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
  value from `defaults`.

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

  _Equivalent to:_

  > optionals true [ "git" "curl" ]
  => [ "git" "curl" ]

  > optionals false [ "git" "curl" ]
  => []

  - __Explicit Attribute Set Configuration__

  > orDefaultIf { condition = true; type = "list"; value = [ "git" ]; }
  => [ "git" ]

  > orDefaultIf { condition = false; type = "list"; value = [ "git" ]; }
  => []

  - __Explicit `default` override (bypasses the `defaults` registry)__

  > orDefaultIf { condition = false; default = "n/a"; value = "enabled"; }
  => "n/a"

  - __Curried positional third slot (`fallback`) is dual-purpose__: if it names a
  key in the type registry it is resolved as a type name, otherwise it is used
  literally as the default value.

  > orDefaultIf false "list" [ 1 2 3 ]
  => []

  > orDefaultIf false "n/a" "hello"
  => "n/a"

  - __No `type`, `default`, or `fallback` given: falls back to the type of `value` itself__

  > orDefaultIf { condition = false; value = "hello"; }
  => ""

  > orDefaultIf { condition = false; value = [ 1 2 3 ]; }
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
            else defaults.${args.type}
            or (throw "${_name}: Unknown type kind '${args.type}'")
          else if hasFallback && isString args.fallback && defaults ? ${args.fallback}
          then defaults.${args.fallback}
          else if hasFallback
          then args.fallback
          else defaults.${typeOf args.value};
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
