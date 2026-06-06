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
        hasLib
        hasModules
        hasOverlays
        isNixpkgsInfrastructure
        isNixpkgsLike
        isNotEmpty
        orEmptyAttr
        orEmptyList
        orEmptyString
        trimString
        filterAttrs
        ;
    };
  inherit
    (builtins)
    attrNames
    attrValues
    concatLists
    filter
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

  /**
  Check if a value is considered "empty" for defaulting purposes.

  # Emptiness Rules
  - `null`:             always empty
  - Strings:            empty when `""` or whitespace-only
  - Lists:              empty when `[]`
  - Attrsets:           empty when `{}`
  - Numbers, booleans, paths, functions: **never** empty

  # Type
  ```nix
  isEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isEmpty null        # => true
  isEmpty ""          # => true
  isEmpty "  "        # => true
  isEmpty []          # => true
  isEmpty {}          # => true
  isEmpty 0           # => false
  isEmpty false       # => false
  isEmpty "hello"     # => false
  isEmpty [1 2 3]     # => false
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
  isNotEmpty = value: !isEmpty value;

  orEmptyAttr = value:
    if (isNotEmpty value && (isAttrs value))
    then value
    else {};

  orEmptyList = value:
    if (isNotEmpty value && (isList value))
    then value
    else [];

  asAttrs = value: let
    type = typeOf value;
  in
    if isAttrs value
    then value
    else if isList value
    then listToAttrs value
    else throw "asAttrs:= Unsupported type: ${type}";

  asAttrsIf = predicate: value:
    if predicate
    then asAttrs value
    else {};

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
    else throw "asList:= Unsupported type: ${type}";

  asListIf = predicate: value:
    if predicate
    then asList value
    else [];

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
  orEmptyString = value:
    if (isNotEmpty value && (isString value))
    then value
    else "";

  /**
  TODO: Add real docs
  */
  filterAttrs = predicate: set:
    listToAttrs
    (
      map (name: {
        inherit name;
        value = set.${name};
      })
      (
        filter
        (name: predicate name set.${name})
        (attrNames set)
      )
    );

  /**
  TODO: Add real docs
  */
  hasLib = input:
    input ? lib;

  /**
  TODO: Add real docs
  */
  hasModules = input:
    input ? nixosModules
    || input ? darwinModules
    || input ? homeModules
    || input ? homeManagerModules;

  /**
  TODO: Add real docs
  */
  hasOverlays = input: input ? overlays;

  /**
  TODO: Add real docs
  */
  isNixpkgsLike = input:
    input ? legacyPackages && input ? lib;

  /**
  TODO: Add real docs
  Inputs that only provide lib/legacyPackages but no user-facing modules/overlays
  */
  isNixpkgsInfrastructure = input:
    (hasLib input || input ? legacyPackages)
    && !(hasModules input)
    && !(hasOverlays input);

  preferDefaultModules = modules:
    if modules ? default
    then [modules.default]
    else attrValues modules;

  collectModules = type: modules: let
    moduleAttr =
      {
        nixos = "nixosModules";
        darwin = "darwinModules";
        home = "homeModules";
      }.${
        type
      };
  in
    if type == "home"
    then
      concatLists (
        attrValues (
          mapAttrs (
            _: input: let
              hasHome = input ? homeModules;
              mods =
                if hasHome
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
              asListIf (input ? ${moduleAttr}) (preferDefaultModules input.${moduleAttr})
          )
          modules
        )
      );
in
  exports
