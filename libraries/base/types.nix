{
  strings,
  attrsets,
  trivial,
  lists,
  debug,
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
  inherit (lists) all;
  inherit (strings) trim';
  inherit (trivial) buildFunction;
  inherit (debug) assertWith;

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
  See original docstring - unchanged.
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
  */
  isNotEmpty = value: !isEmpty value;

  /**
  Return the first value when it is not `null`; otherwise return the fallback.

  # Type
  ```nix
  coalesce :: AttrSet -> a
  coalesce :: a -> a -> a
  ```
  */
  coalesce = buildFunction {
    name = "types.coalesce";
    positional = ["value" "default"];
    required = ["value" "default"];

    #> Both fields accept anything, including null - no per-field validation needed.
    validation = {};

    simulation = [
      {
        args = {
          value = "hello";
          default = "fallback";
        };
        desired = "hello";
      }
      {
        args = {
          value = null;
          default = "fallback";
        };
        desired = "fallback";
      }
      {
        args = ["" "fallback"];
        desired = "";
      }
      {
        args = [null "fallback"];
        desired = "fallback";
      }
      {
        args = [[] ["a"]];
        desired = [];
      }
    ];

    execution = args:
      orDefaultIf {
        condition = args.value != null;
        inherit (args) default value;
      };
  };

  /**
  Return a value when it has the requested Nix type; otherwise return that
  type's registered default value.

  # Type
  ```nix
  orDefault :: AttrSet -> a
  orDefault :: String -> a -> a
  ```
  */
  orDefault = let
    _name = "types.orDefault";
  in
    buildFunction {
      name = _name;
      positional = ["default" "value"];
      required = ["value"];
      optional = ["default" "type"];

      validation = {};

      simulation = [
        {
          args = ["list" ["value"]];
          desired = ["value"];
        }
        {
          args = ["list" "value"];
          desired = [];
        }
        {
          args = ["string" null];
          desired = "";
        }
        {
          args = {
            type = "set";
            value = ["value"];
          };
          desired = {};
        }
        {
          args = {
            value = "x";
            default = "d";
            type = "string";
          };
          throws = true;
        }
      ];

      execution = args: let
        hasDefault = args ? default;
        hasType = args ? type;

        check = assertWith {
          name = _name;
          assertion = hasDefault != hasType; #> exactly one, i.e. XOR
          message = "provide either 'default' or 'type', not both, and not neither";
          context = "execution";
        };

        default =
          if hasDefault
          then args.default
          else defaults.${args.type}
          or (throw "${_name}: Unknown type kind '${args.type}'");
      in
        assert check;
          orDefaultIf {
            condition = isNotEmpty args.value;
            inherit default;
            inherit (args) value;
          };
    };

  /**
  Return a value when a condition is true; otherwise return the registered
  default for the requested type.

  # Type
  ```nix
  orDefaultIf :: AttrSet -> a
  orDefaultIf :: Bool -> String -> a -> a
  ```
  */
  orDefaultIf = let
    _name = "types.orDefaultIf";
  in
    buildFunction {
      name = _name;
      positional = ["condition" "fallback" "value"];
      required = ["condition" "value"];
      optional = ["fallback" "type" "default"];

      validation = {
        condition = {
          validate = input:
            if typeOf input != "bool"
            then throw "${_name}: condition must be a bool"
            else input;
          type = "bool";
        };
      };

      simulation = [
        {
          args = [true "set" {enable = true;}];
          desired = {enable = true;};
        }
        {
          args = [false "set" {enable = true;}];
          desired = {};
        }
        {
          args = [true "list" ["git" "curl"]];
          desired = ["git" "curl"];
        }
        {
          args = [false "list" ["git" "curl"]];
          desired = [];
        }
        {
          args = [true "string" "enabled"];
          desired = "enabled";
        }
        {
          args = [false "string" "enabled"];
          desired = "";
        }
        {
          args = {
            condition = true;
            type = "list";
            value = ["git"];
          };
          desired = ["git"];
        }
        {
          args = {
            condition = false;
            type = "list";
            value = ["git"];
          };
          desired = [];
        }
        {
          args = {
            condition = false;
            default = "n/a";
            value = "enabled";
          };
          desired = "n/a";
        }
        {
          args = [false "n/a" "hello"];
          desired = "n/a";
        }
        {
          args = {
            condition = false;
            value = "hello";
          };
          desired = "";
        }
        {
          args = {
            condition = false;
            value = [1 2 3];
          };
          desired = [];
        }
        #> condition must be a bool
        {
          args = ["not-a-bool" "list" []];
          throws = true;
        }
      ];

      execution = args: let
        hasType = args ? type;
        hasDefault = args ? default;
        hasFallback = args ? fallback;

        check = assertWith {
          name = _name;
          assertion = !(hasType && hasDefault);
          message = "provide either 'type' or 'default', not both";
          context = "execution";
        };

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
          else fallback;
    };
in
  exports
