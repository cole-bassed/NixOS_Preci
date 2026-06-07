let
  exports =
    builtins
    // {
      inherit
        asAttrs
        asAttrsIf
        asList
        asListIf
        collectModules
        filterAttrs
        hasLib
        hasModules
        hasOverlays
        inspectAttrs
        inheritAttr
        isNotEmpty
        isFlakeLike
        isHomeManagerLike
        isNixDarwinLike
        isNixpkgsInfrastructure
        isNixpkgsLike
        isTreefmtLike
        mkDots
        orEmptyAttrs
        orEmptyList
        orEmptyString
        pickFirst
        preferDefaultModules
        recursiveUpdate
        trimString
        ;
    };

  inherit
    (builtins)
    attrNames
    attrValues
    concatLists
    filter
    getAttr
    hasAttr
    head
    isAttrs
    isFunction
    isList
    isString
    listToAttrs
    mapAttrs
    match
    stringLength
    typeOf
    ;

  inspectAttrs = level: let
    fn = depth: value: let
      type = typeOf value;
    in
      if depth <= 0
      then "..."
      else if isFunction value
      then "<function>"
      else if isList value
      then map (fn (depth - 1)) value
      else if isAttrs value
      then mapAttrs (_: fn (depth - 1)) value
      else if type == "path"
      then "<path>"
      else value;
  in
    fn level;

  recursiveUpdate = lhs: rhs:
    if isAttrs lhs && isAttrs rhs
    then
      listToAttrs (
        map (key: {
          name = key;
          value =
            if lhs ? ${key} && rhs ? ${key}
            then recursiveUpdate lhs.${key} rhs.${key}
            else if rhs ? ${key}
            then rhs.${key}
            else lhs.${key};
        }) (attrNames (lhs // rhs))
      )
    else rhs;

  mkDots = paths: host: {
    dots = {
      store = toString paths.src;
      local = host.paths.src or (throw "mkDots:= Host must define 'paths.src' as the local path to the flake");
    };
  };

  /**
  Trim leading and trailing whitespace from a string.

  Non-string values are treated as the empty string.

  # Type
  ```nix
  trimString :: a -> String
  ```

  # Arguments

  value
  : The value to trim. Non-string values produce `""`.

  # Examples
  ```nix
  trimString "  hello  "
  => "hello"
  ```

  ```nix
  trimString "\n  hi there\t"
  => "hi there"
  ```

  ```nix
  trimString null
  => ""
  ```
  */
  trimString = value: let
    string =
      if isString value
      then value
      else "";
    matches = match "[[:space:]]*(.*[^[:space:]])?[[:space:]]*" string;
  in
    if matches != null
    then head matches
    else "";

  /**
  Check if a value is considered empty for defaulting purposes.

  Emptiness rules:
  - `null` is empty
  - strings are empty when `""` or whitespace-only
  - lists are empty when `[]`
  - attrsets are empty when `{}`
  - numbers, booleans, and paths are never empty
  - functions are unsupported and cause an error

  # Type
  ```nix
  isEmpty :: a -> Bool
  ```

  # Arguments

  value
  : The value to test.

  # Examples
  ```nix
  isEmpty null
  => true
  ```

  ```nix
  isEmpty "   "
  => true
  ```

  ```nix
  isEmpty {}
  => true
  ```

  ```nix
  isEmpty [ 1 ]
  => false
  ```
  */
  isEmpty = value:
    assert !isFunction value || throw "isEmpty:= functions are not supported";
      if value == null
      then true
      else if isString value
      then value == "" || stringLength (trimString value) == 0
      else if isList value
      then value == []
      else if isAttrs value
      then value == {}
      else false;

  /**
  Return whether a value is not empty according to `isEmpty`.

  # Type
  ```nix
  isNotEmpty :: a -> Bool
  ```

  # Arguments

  value
  : The value to test.

  # Examples
  ```nix
  isNotEmpty "hello"
  => true
  ```

  ```nix
  isNotEmpty []
  => false
  ```
  */
  isNotEmpty = value: !isEmpty value;

  /**
  Normalize a value to a non-empty attrset.

  Returns the attrset unchanged when `value` is a non-empty attrset.
  Returns `{}` for empty attrsets and for any non-attrset value, including
  `null`, `[]`, and `""`.

  # Type
  ```nix
  orEmptyAttrs :: a -> { ... }
  ```

  # Arguments

  value
  : The value to normalize.

  # Examples
  ```nix
  orEmptyAttrs { a = 1; }
  => { a = 1; }
  ```

  ```nix
  orEmptyAttrs {}
  => {}
  ```

  ```nix
  orEmptyAttrs null
  => {}
  ```

  ```nix
  orEmptyAttrs []
  => {}
  ```

  ```nix
  orEmptyAttrs ""
  => {}
  ```

  ```nix
  orEmptyAttrs [ 1 ]
  => {}
  ```
  */
  orEmptyAttrs = value:
    if isAttrs value && isNotEmpty value
    then value
    else {};

  /**
  Return a non-empty list as-is, otherwise return `[]`.

  A value is kept only when it is both a list and not empty according to
  `isNotEmpty`.

  # Type
  ```nix
  orEmptyList :: a -> [ b ]
  ```

  # Arguments

  value
  : The value to normalize.

  # Examples
  ```nix
  orEmptyList [ 1 2 ]
  => [ 1 2 ]
  ```

  ```nix
  orEmptyList []
  => []
  ```

  ```nix
  orEmptyList null
  => []
  ```

  ```nix
  orEmptyList "hello"
  => []
  ```
  */
  orEmptyList = value:
    if isList value && isNotEmpty value
    then value
    else [];

  /**
  Return a non-empty string as-is, otherwise return `""`.

  Strings containing only whitespace are treated as empty because `isEmpty`
  trims strings before checking length.

  # Type
  ```nix
  orEmptyString :: a -> String
  ```

  # Arguments

  value
  : The value to normalize.

  # Examples
  ```nix
  orEmptyString "hello"
  => "hello"
  ```

  ```nix
  orEmptyString "   "
  => ""
  ```

  ```nix
  orEmptyString null
  => ""
  ```

  ```nix
  orEmptyString [ 1 ]
  => ""
  ```
  */
  orEmptyString = value:
    if isString value && isNotEmpty value
    then value
    else "";

  /**
  Inherit a named attribute from a source attrset when it exists.

  This helper supports two call forms:

  - Curried form: `inheritAttr name set`
  - Attrset form: `inheritAttr { name = ...; set = ...; }`

  If `set` contains `name`, the result is an attrset containing only that
  inherited attribute. Otherwise `{}` is returned.

  The curried form is the canonical public API because it matches the shape
  of `builtins.getAttr`.

  # Type
  ```nix
  inheritAttr :: String -> { ... } -> { ... }
  inheritAttr :: { name :: String; set :: { ... }; ... } -> { ... }
  ```

  # Arguments

  name
  : The attribute name to inherit.

  set
  : The source attrset.

  # Examples
  ```nix
  inheritAttr "flake" {
    flake = { a = 1; };
  }
  => { flake = { a = 1; }; }
  ```

  ```nix
  inheritAttr "flake" {}
  => {}
  ```

  ```nix
  inheritAttr {
    name = "flake";
    set = {
      flake = { a = 1; };
    };
  }
  => { flake = { a = 1; }; }
  ```
  */
  inheritAttr = nameOrArgs:
    if isAttrs nameOrArgs
    then let
      name = nameOrArgs.name or null;
      set = nameOrArgs.set or null;
    in
      if name == null || set == null
      then throw "inheritAttr:= expected { name, set; }"
      else if hasAttr name set
      then {${name} = getAttr name set;}
      else {}
    else
      set:
        if hasAttr nameOrArgs set
        then {${nameOrArgs} = getAttr nameOrArgs set;}
        else {};

  /**
  Coerce a value into an attrset.

  Supported inputs:
  - attrsets are returned unchanged
  - strings become `{ ${value} = true; }`
  - lists become an attrset of boolean flags keyed by list entries

  # Type
  ```nix
  asAttrs :: { ... } | String | [ String ] -> { ... }
  ```

  # Arguments

  value
  : The value to coerce.

  # Examples
  ```nix
  asAttrs { a = 1; }
  => { a = 1; }
  ```

  ```nix
  asAttrs "debug"
  => { debug = true; }
  ```

  ```nix
  asAttrs [ "debug" "types" ]
  => { debug = true; types = true; }
  ```
  */
  asAttrs = value: let
    type = typeOf value;
  in
    if isAttrs value
    then value
    else if isString value
    then {${value} = true;}
    else if isList value
    then
      listToAttrs (
        map (name: {
          inherit name;
          value = true;
        })
        value
      )
    else throw "asAttrs:= unsupported type: ${type}";

  /**
  Conditionally coerce a value into an attrset.

  Returns `asAttrs value` when `predicate` is true, otherwise `{}`.

  # Type
  ```nix
  asAttrsIf :: Bool -> ({ ... } | String | [ String ]) -> { ... }
  ```

  # Arguments

  predicate
  : Whether coercion should happen.

  value
  : The value to coerce when enabled.

  # Examples
  ```nix
  asAttrsIf true "flake"
  => { flake = true; }
  ```

  ```nix
  asAttrsIf false "flake"
  => {}
  ```
  */
  asAttrsIf = predicate: value:
    if predicate
    then asAttrs value
    else {};

  /**
  Coerce a value into a list.

  Supported inputs:
  - lists are returned unchanged
  - strings are wrapped as singleton lists
  - attrsets become `attrNames value`
  - paths are wrapped as singleton lists

  # Type
  ```nix
  asList :: [ a ] | String | { ${String} :: b; } | Path -> [ a ] | [ String ] | [ Path ]
  ```

  # Arguments

  value
  : The value to coerce.

  # Examples
  ```nix
  asList "pop"
  => [ "pop" ]
  ```

  ```nix
  asList { a = 1; b = 2; }
  => [ "a" "b" ]
  ```

  ```nix
  asList ./file.nix
  => [ ./file.nix ]
  ```
  */
  asList = value: let
    type = typeOf value;
  in
    if isList value
    then value
    else if isString value
    then [value]
    else if isAttrs value
    then attrNames value
    else if type == "path"
    then [value]
    else throw "asList:= unsupported type: ${type}";

  /**
  Conditionally coerce a value into a list.

  Returns `asList value` when `predicate` is true, otherwise `[]`.

  # Type
  ```nix
  asListIf :: Bool -> a -> [ b ]
  ```

  # Arguments

  predicate
  : Whether coercion should happen.

  value
  : The value to coerce when enabled.

  # Examples
  ```nix
  asListIf true "debug"
  => [ "debug" ]
  ```

  ```nix
  asListIf false "debug"
  => []
  ```
  */
  asListIf = predicate: value:
    if predicate
    then asList value
    else [];

  /**
  Filter an attribute set by attribute name and value.

  Returns a new attrset containing only the attributes for which
  `predicate name value` returns true.

  # Type
  ```nix
  filterAttrs :: (String -> a -> Bool) -> { ${String} :: a; } -> { ${String} :: a; }
  ```

  # Arguments

  predicate
  : A function taking an attribute name and value and returning whether it should be kept.

  set
  : The attrset to filter.

  # Examples
  ```nix
  filterAttrs (_: v: v != null) { a = 1; b = null; }
  => { a = 1; }
  ```

  ```nix
  filterAttrs (n: _: n == "a") { a = 1; b = 2; }
  => { a = 1; }
  ```
  */
  filterAttrs = predicate: set:
    listToAttrs (
      map (name: {
        inherit name;
        value = set.${name};
      }) (
        filter (name: predicate name set.${name}) (attrNames set)
      )
    );

  /**
  Return whether an input exposes a `lib` attribute.

  # Type
  ```nix
  hasLib :: { ... } -> Bool
  ```

  # Arguments

  input
  : The input attrset to inspect.

  # Examples
  ```nix
  hasLib { lib = {}; }
  => true
  ```

  ```nix
  hasLib {}
  => false
  ```
  */
  hasLib = input:
    input ? lib;

  /**
  Return whether an input exposes any recognized module namespace.

  Recognized module namespaces are:
  - `nixosModules`
  - `darwinModules`
  - `homeModules`
  - `homeManagerModules`

  # Type
  ```nix
  hasModules :: { ... } -> Bool
  ```

  # Arguments

  input
  : The input attrset to inspect.

  # Examples
  ```nix
  hasModules { nixosModules = {}; }
  => true
  ```

  ```nix
  hasModules { overlays = {}; }
  => false
  ```
  */
  hasModules = input:
    input ? nixosModules
    || input ? darwinModules
    || input ? homeModules
    || input ? homeManagerModules;

  /**
  Return whether an input exposes overlays.

  # Type
  ```nix
  hasOverlays :: { ... } -> Bool
  ```

  # Arguments

  input
  : The input attrset to inspect.

  # Examples
  ```nix
  hasOverlays { overlays = {}; }
  => true
  ```

  ```nix
  hasOverlays {}
  => false
  ```
  */
  hasOverlays = input:
    input ? overlays;

  /**
  Return whether an input summary should be treated as flake-like.

  An input summary is considered flake-like when it contains at least one
  meaningful flake-facing capability:
  - classified modules
  - classified overlays
  - normalized nixpkgs

  # Type
  ```nix
  isFlakeLike :: {
    classified :: {
      modules :: { ... };
      overlays :: { ... };
      ...
    };
    normalized :: {
      nixpkgs :: { ... };
      ...
    };
    ...
  } -> Bool
  ```

  # Arguments

  inputs
  : A summary attrset containing `classified` and `normalized`.

  # Examples
  ```nix
  isFlakeLike {
    classified = {
      modules = { foo = {}; };
      overlays = {};
    };
    normalized = {
      nixpkgs = {};
    };
  }
  => true
  ```

  ```nix
  isFlakeLike {
    classified = {
      modules = {};
      overlays = {};
    };
    normalized = {
      nixpkgs = {};
    };
  }
  => false
  ```
  */
  isFlakeLike = inputs:
    isNotEmpty (inputs.classified.modules or {})
    || isNotEmpty (inputs.classified.overlays or {})
    || isNotEmpty (inputs.normalized.nixpkgs or {});

  /**
  Return whether an input looks like a nixpkgs-style input.

  A nixpkgs-like input exposes both `legacyPackages` and `lib`.

  # Type
  ```nix
  isNixpkgsLike :: { ... } -> Bool
  ```

  # Arguments

  input
  : The input attrset to inspect.

  # Examples
  ```nix
  isNixpkgsLike {
    legacyPackages = {};
    lib = {};
  }
  => true
  ```

  ```nix
  isNixpkgsLike { lib = {}; }
  => false
  ```
  */
  isNixpkgsLike = input:
    input ? legacyPackages
    && input ? lib
    && !(input ? __functor);

  isNixDarwinLike = input:
    input ? darwinModules
    && input ? lib
    && !(input ? legacyPackages)
    && !(input ? nixosModules)
    && !(input ? homeModules)
    && !(input ? homeManagerModules);

  isHomeManagerLike = input:
    input ? nixosModules
    && input ? darwinModules
    && input ? legacyPackages
    && input ? lib
    && input ? flakeModules
    && !(input ? homeModules);

  isTreefmtLike = input:
    input ? lib
    && input.lib ? evalModule
    && input ? flakeModule
    && !(input ? legacyPackages)
    && !(hasModules input)
    && !(hasOverlays input);

  /**
  Return whether an input is nixpkgs-like infrastructure only.

  These are inputs that expose `lib` or `legacyPackages` but do not provide
  user-facing modules or overlays.

  # Type
  ```nix
  isNixpkgsInfrastructure :: { ... } -> Bool
  ```

  # Arguments

  input
  : The input attrset to inspect.

  # Examples
  ```nix
  isNixpkgsInfrastructure { lib = {}; }
  => true
  ```

  ```nix
  isNixpkgsInfrastructure {
    lib = {};
    overlays = {};
  }
  => false
  ```
  */
  # isNixpkgsInfrastructure = input:
  #   (hasLib input || input ? legacyPackages)
  #   && !(hasModules input)
  #   && !(hasOverlays input);
  isNixpkgsInfrastructure = input:
    isNixpkgsLike input
    && !(hasModules input)
    && !(hasOverlays input);

  /**
  Prefer a module set's `default` entry when present.

  If `modules.default` exists, returns a singleton list containing only that
  module. Otherwise returns all attribute values of the module set.

  # Type
  ```nix
  preferDefaultModules :: { default :: a; ... } | { ${String} :: a; } -> [ a ]
  ```

  # Arguments

  modules
  : A module attrset.

  # Examples
  ```nix
  preferDefaultModules {
    default = ./default.nix;
    extra = ./extra.nix;
  }
  => [ ./default.nix ]
  ```

  ```nix
  preferDefaultModules {
    a = ./a.nix;
    b = ./b.nix;
  }
  => [ ./a.nix ./b.nix ]
  ```
  */
  preferDefaultModules = modules:
    if modules ? default
    then [modules.default]
    else attrValues modules;

  /**
  Collect modules of a given type from a set of flake inputs.

  Supported types are:
  - `nixos`
  - `darwin`
  - `home`

  For `home`, both `homeModules` and `homeManagerModules` are supported.
  When a module namespace provides a `default` attribute, only that module is
  selected. Otherwise all module values are collected.

  Invalid module types cause an explicit error.

  # Type
  ```nix
  collectModules :: String -> { ${String} :: { ... }; } -> [ a ]
  ```

  # Arguments

  type
  : The module type to collect. Supported values are `"nixos"`, `"darwin"`, and `"home"`.

  modules
  : An attrset of candidate inputs.

  # Examples
  ```nix
  collectModules "nixos" {
    foo = { nixosModules.default = ./foo.nix; };
    bar = { nixosModules.default = ./bar.nix; };
  }
  => [ ./foo.nix ./bar.nix ]
  ```

  ```nix
  collectModules "home" {
    hm = { homeManagerModules.default = ./home.nix; };
  }
  => [ ./home.nix ]
  ```
  */
  collectModules = type: modules: let
    # Bring in standard unique list filter to discard duplicate file targets
    unique =
      builtins.createSymbols or (items: let
        # Fallback unique filter logic if lib isn't inherited here yet
        dedup = list:
          if list == []
          then []
          else [(builtins.head list)] ++ dedup (builtins.filter (x: x != builtins.head list) (builtins.tail list));
      in
        dedup items);

    moduleAttr =
      if type == "nixos"
      then "nixosModules"
      else if type == "darwin"
      then "darwinModules"
      else if type == "home"
      then "homeModules"
      else throw "collectModules:= unsupported type '${type}'";

    # Store the raw aggregated results
    rawCollected =
      if type == "home"
      then
        concatLists (
          attrValues (
            mapAttrs (
              _: input: let
                mods =
                  if hasAttr "homeModules" input
                  then input.homeModules
                  else (input.homeManagerModules or {});
              in
                preferDefaultModules mods
            )
            modules
          )
        )
      else
        concatLists (
          attrValues (
            mapAttrs (
              _: input:
                asListIf
                (hasAttr moduleAttr input)
                (preferDefaultModules (getAttr moduleAttr input))
            )
            modules
          )
        );
  in
    # ── CRITICAL FIX: DEDUPLICATE COLLECTED FILE PATHS ──────────────────────
    # Ensures no module path or file object is added to the system list twice
    unique rawCollected;

  # collectModules = type: modules: let
  #   moduleAttr =
  #     if type == "nixos"
  #     then "nixosModules"
  #     else if type == "darwin"
  #     then "darwinModules"
  #     else if type == "home"
  #     then "homeModules"
  #     else throw "collectModules:= unsupported type '${type}'";
  # in
  #   if type == "home"
  #   then
  #     concatLists (
  #       attrValues (
  #         mapAttrs (
  #           _: input: let
  #             mods =
  #               if hasAttr "homeModules" input
  #               then input.homeModules
  #               else (input.homeManagerModules or {});
  #           in
  #             preferDefaultModules mods
  #         )
  #         modules
  #       )
  #     )
  #   else
  #     concatLists (
  #       attrValues (
  #         mapAttrs (
  #           _: input:
  #             asListIf
  #             (hasAttr moduleAttr input)
  #             (preferDefaultModules (getAttr moduleAttr input))
  #         )
  #         modules
  #       )
  #     );

  pickFirst = attrs:
    if attrs == {}
    then null
    else head (attrValues attrs);
in
  exports
