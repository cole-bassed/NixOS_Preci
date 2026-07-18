{
  attrsets,
  debug,
  lists,
  strings,
  types,
  ...
}: let
  exports = {
    scoped = {
      inherit
        findFirst
        getBySpec
        getOrderedOr
        inspect
        normalize
        inspectJSON
        isEmpty
        isNotEmpty
        mapOrdered
        mapParsedOrdered
        mergeUnique
        orDefault
        orEmpty
        orNull
        parseOrdered
        removeEmpty
        resolveBySpecs
        toOrdered
        # foldMerge
        mkNamespaced
        extractArgs
        ;
      dropNull = removeEmpty;
      merge = mergeUnique;
      orderedOf = toOrdered;
      parsedOf = parseOrdered;
      # inherit mapAttrs;
    };
    global = {
      normalizeAttrs = normalize;
      findFirstAttrs = findFirst;
      getAttrBySpec = getBySpec;
      inspectAttr = inspect;
      inspectAttrJSON = inspectJSON;
      isEmptyAttr = isEmpty;
      isNotEmptyAttr = isNotEmpty;
      mapOrderedAttrs = mapOrdered;
      mapParsedOrderedAttrs = mapParsedOrdered;
      mergeUniqueAttrs = mergeUnique;
      mkNamespacedAttrs = mkNamespaced;
      orDefaultAttr = orDefault;
      orEmptyAttr = orEmpty;
      orNullAttr = orNull;
      parseOrderedAttrs = parseOrdered;
      removeEmptyAttrs = removeEmpty;
      resolveAttrsBySpecs = resolveBySpecs;
      toOrderedAttrs = toOrdered;
    };
  };

  inherit
    (attrsets)
    namesOf
    concatMapAttrs
    filterAttrs
    genAttrs
    hasAttr
    attrByPath
    getAttr
    listToAttrs
    mapAttrs
    optionalAttrs
    # recursiveUpdate
    ;
  inherit
    (lists)
    all
    concatMap
    elem
    filter
    findFirstList
    foldl'
    genList
    head
    isList
    length
    map
    nthOr
    uniqueStrings
    ;
  inherit (strings) concatStringsSep toJSON toUpper substring;
  inherit (debug) withContext;
  inherit (types) isAttrs typeOf isString isFunction' isPath;

  isEmpty = input: (input == null) || (isAttrs input && input == {});
  isNotEmpty = input: !isEmpty input;
  removeEmpty = sets: filterAttrs (_: value: (isNotEmpty value)) sets;

  orNull = input:
    assert withContext {
      name = "attrsets.orNull";
      assertion = types.isEmpty input || isAttrs input;
      message = "expected an attrset, got ${typeOf input}";
      context = "evaluating attrsets.orNull";
    };
      if types.isEmpty input || !(isAttrs input)
      then null
      else input;

  orDefault = default: input:
    assert withContext {
      name = "attrsets.orDefault";
      assertion = isAttrs default && isAttrs input;
      message = "expected attrsets, got default=${typeOf default} input=${typeOf input}";
      context = "evaluating attrsets.orDefault";
    };
      if isNotEmpty input
      then input
      else default;

  orEmpty = input:
    assert withContext {
      name = "attrsets.orEmpty";
      assertion = isNull input || isAttrs input;
      message = "expected an attrset or null, got ${typeOf input}";
      context = "evaluating attrsets.orEmpty";
    };
      optionalAttrs (isNotEmpty input) input;

  inspect = level: let
    fn = depth: value:
      if depth <= 0
      then "..."
      # else if builtins.isFunction value
      else if isFunction' value
      then "<function>"
      else if isPath value
      then "<path>"
      else if isList value
      then map (fn (depth - 1)) value
      else if isAttrs value
      then mapAttrs (_: fn (depth - 1)) value
      else value;
  in
    fn level;

  inspectJSON = level: value:
    toJSON (inspect level value);

  getBySpec = input: spec:
    assert withContext {
      name = "attrsets.getBySpec";
      assertion = isNull input || isAttrs input;
      message = "expected input to be an attrset or null, got ${typeOf input}";
      context = "evaluating attrsets.getBySpec";
    };
      if input == null
      then null
      else if isList spec
      then attrByPath spec null input
      else if isString spec && hasAttr spec input
      then getAttr spec input
      else null;

  findFirst = {
    sets,
    specs,
    default ? null,
  }:
    assert withContext {
      name = "attrsets.findFirst'";
      assertion = isList sets && isList specs;
      message = "expected sets and specs to be lists";
      context = "evaluating attrsets.findFirst";
    };
      findFirstList (x: x != null) default
      (concatMap (input: map (spec: getBySpec input spec) specs) sets);

  resolveBySpecs = {
    input,
    specs,
    default ? null,
  }:
    assert withContext {
      name = "attrsets.resolveBySpecs";
      assertion = (input == null || isAttrs input) && isList specs;
      message = "expected input to be an attrset or null, and specs to be a list";
      context = "evaluating attrsets.resolveBySpecs";
    };
      findFirst {
        sets = [input];
        inherit specs default;
      };

  mergeUnique = {
    items,
    attrs,
    what ? "attributes",
    owner ? (name: name),
  }:
    foldl'
    (
      acc: name: let
        incoming = attrs name;
        collisions = filter (key: hasAttr key acc) (namesOf incoming);
      in
        if collisions == []
        then acc // incoming
        else
          throw ''
            ${what}: collision(s) detected in '${owner name}':
              ${concatStringsSep ", " collisions}
            Each merged attribute name must be unique.
          ''
    )
    {}
    (namesOf items);

  getOrderedOr = {
    key,
    set,
    default ? null,
  }:
    if hasAttr key set
    then getAttr key set
    else default;

  toOrdered = {value}: let
    count =
      if isList value
      then length value
      else 1;
  in
    listToAttrs (
      map (position: {
        name = toString (position + 1);
        value = nthOr {
          inherit position value;
        };
      }) (genList (x: x) count)
    );

  mapOrdered = set:
    mapAttrs (_: value: toOrdered {inherit value;}) set;

  parseOrdered = value: let
    ordered =
      if isAttrs value
      then value
      else toOrdered {inherit value;};

    primary = getOrderedOr {
      key = "1";
      set = ordered;
    };
    secondary = getOrderedOr {
      key = "2";
      set = ordered;
    };
    tertiary = getOrderedOr {
      key = "3";
      set = ordered;
    };

    preferred = primary;
    fallback = secondary;

    default =
      if isList value
      then
        if value == []
        then null
        else
          nthOr {
            position = (length value) - 1;
            inherit value;
          }
      else if isAttrs value
      then
        getOrderedOr {
          key = "default";
          set = value;
          default = primary;
        }
      else value;
  in
    ordered
    // {inherit primary secondary tertiary preferred fallback default;};

  mapParsedOrdered = set: mapAttrs (_: parseOrdered) set;

  mkNamespaced = payload: let
    args = extractArgs {
      args = payload;
      required = ["sets"];
      defaults = {transformation = "camelCase";};
    };

    styleMap =
      {
        camelCase = prefix: name:
          if name == ""
          then prefix
          else "${prefix}${toUpper (substring 0 1 name)}${substring 1 (-1) name}";

        shell = prefix: name:
          if name == ""
          then toUpper prefix
          else "${toUpper prefix}_${toUpper name}";

        none = prefix: name: "${prefix}${name}";
      }
      // {POSIX = styleMap.shell;};

    formatName = styleMap.${args.transformation} or styleMap.camelCase;
  in
    concatMapAttrs (
      prefix: attrset:
        listToAttrs (map (name: {
          name = formatName prefix name;
          value = attrset.${name};
        }) (namesOf attrset))
    )
    args.sets;

  # foldMerge = list:
  #   foldl' recursiveUpdate {} (filter isAttrs list);

  normalize = args: let
    isDescriptor =
      isAttrs args
      && args ? flag
      && isString args.flag
      && args ? value;

    input = {
      flag =
        if isDescriptor
        then args.flag
        else "enable";
      value =
        if isDescriptor
        then args.value
        else args;
    };

    inherit (input) flag value;

    resolved = {
      ${flag} = true;
      inherit value;
    };

    type = typeOf value;

    list = genAttrs value (_: removeAttrs resolved ["value"]);
    bool = {${flag} = value;};
    set =
      if value ? ${flag} || value ? value
      then (removeAttrs value ["value"]) // {${flag} = value.${flag} or true;}
      else mapAttrs (_: value: normalize {inherit flag value;}) value;

    handlers = {inherit list bool set;};
  in
    handlers.${type} or resolved;

  extractArgs = {
    args ? null,
    payload ? null,
    required ? [],
    optional ? allowed,
    defaults ? {},
    # Automatically derive allowed keys so you rarely have to define them manually
    allowed ? required ++ (namesOf defaults),
    # Where to put the raw data if args is a legacy payload
    legacyMapKey ? (head required),
  }: let
    value =
      if args != null
      then args
      else if payload != null
      then payload
      else throw "extractArgs: no args or payload provided";
    check =
      (isAttrs value)
      && (all (req: hasAttr req value) required)
      && (
        all
        (key: elem key (uniqueStrings (allowed ++ optional)))
        (namesOf value)
      );
  in
    if check
    then defaults // value
    else defaults // {"${legacyMapKey}" = value;};
in
  exports
