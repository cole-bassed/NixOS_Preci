{
  lib,
  lix,
  ...
}: let
  exports = let
    functions = {
      inherit
        isEmpty
        isList
        isNotEmpty
        isValidGeoCoords
        ;
    };
    aliases = {};
    internal = re-exports // functions // aliases // {};
    external = functions // aliases;
  in {inherit functions aliases internal external;};

  inherit (lix.debug) withContext;
  inherit (lix.lists) head tail isList reverseList;
  inherit (lix.strings) concatStrings stringLength;
  inherit (re-exports) isAttrs isFloat isFunction isString;

  # Minimal local trim so predicates doesn't circularly depend on strings.
  trim = s: let
    chars = lib.stringToCharacters s;
    isSpace = c: c == " " || c == "\t" || c == "\n" || c == "\r";
    dropWhile = pred: list:
      if list == []
      then []
      else if pred (head list)
      then dropWhile pred (tail list)
      else list;
    trimmed = dropWhile isSpace (
      lib.reverseList (dropWhile isSpace (reverseList chars))
    );
  in
    concatStrings trimmed;

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
    assert withContext {
      name = "isEmpty";
      assertion = !isFunction value;
      message = "functions are not supported";
      context = "evaluating isEmpty";
    };
      if value == null
      then true
      else if isString value
      then value == "" || stringLength (trim value) == 0
      else if isList value
      then value == []
      else if isAttrs value
      then value == {}
      else false;

  /**
  Check if a value is not empty. Convenience negation of `isEmpty`.

  # Type
  ```nix
  isNotEmpty :: a -> Bool
  ```

  # Examples
  ```nix
  isNotEmpty "hello"  # => true
  isNotEmpty 0        # => true
  isNotEmpty false    # => true
  isNotEmpty null     # => false
  isNotEmpty ""       # => false

  # Common use in filters
  validItems = filter isNotEmpty rawList;
  ```
  */
  isNotEmpty = value: !isEmpty value;

  isValidGeoCoords = {
    longitude,
    latitude,
  }:
    (isFloat longitude && (longitude >= -180.0) && (longitude <= 180.0))
    && (isFloat latitude && (latitude >= -180.0) && (latitude <= 180.0));

  re-exports = {
    inherit (lib.trivial) isBool isFloat isFunction;
    inherit
      (lib.strings)
      isAttrs
      isConvertibleWithToString
      isInt
      isList
      isPath
      isStorePath
      isString
      isStringLike
      isValidPosixName
      typeOf
      ;
    inherit
      (lib.types)
      addCheck
      anything
      attrs
      attrsOf
      attrsWith
      attrTag
      bool
      boolByOr
      coercedTo
      commas
      defaultFunctor
      defaultTypeMerge
      deferredModule
      deferredModuleWith
      either
      enum
      envVar
      externalPath
      fileset
      float
      functionTo
      int
      ints
      isOptionType
      isType
      json
      lazyAttrsOf
      lines
      listOf
      loaOf
      luaInline
      mergeTypes
      mkOptionType
      noCheckForDocsModule
      nonEmptyListOf
      nonEmptyStr
      nullOr
      number
      numbers
      oneOf
      optionDeclaration
      optionDescriptionPhrase
      optionType
      package
      passwdEntry
      path
      pathInStore
      pathWith
      pkgs
      port
      raw
      separatedString
      serializableValueWith
      setType
      shellPackage
      singleLineStr
      str
      strMatching
      submodule
      submoduleWith
      toml
      uniq
      unique
      unspecified
      ;
  };
in
  exports
