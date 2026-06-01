{lix}: let
  exports = {
    internal = {
      inherit
        getOrderedOr
        toOrdered
        mapOrdered
        parseOrdered
        mapParsedOrdered
        mergeUnique
        orNull
        orDefault
        orEmpty
        ;
      orderedOf = toOrdered;
      parsedOf = parseOrdered;
      merge = mergeUnique;

      isEmpty = isEmpty';
      isNotEmpty = isEmpty';
    };
    external = {
      orNullAttr = orNull;
      orDefaultAttr = orDefault;
      orEmptyAttr = orEmpty;
      toOrderedAttrs = toOrdered;
      mapOrderedAttrs = mapOrdered;
      parseOrderedAttrs = parseOrdered;
      mapParsedOrderedAttrs = mapParsedOrdered;
      mergeUniqueAttrs = mergeUnique;
      isEmptyAttr = isEmpty';
      isNotEmptyAttr = isNotEmpty';
    };
  };

  inherit (lix.attrsets) attrNames hasAttr getAttr listToAttrs mapAttrs optionalAttrs;
  inherit (lix.lists) filter foldl' genList isList length nthOr;
  inherit (lix.strings) concatStringsSep;
  inherit (lix.debug) withContext;
  inherit (lix.types) isAttrs isEmpty typeOf;

  isEmpty' = value: value == {};
  isNotEmpty' = value: !isEmpty' value;

  orNull = value:
    assert withContext {
      name = "attrs.orNull";
      assertion = isEmpty value || isAttrs value;
      message = "expected an attrset, got ${typeOf value}";
      context = "evaluating attrs.orNull";
    };
      if isEmpty value || !(isAttrs value)
      then null
      else value;

  orDefault = default: value:
    assert withContext {
      name = "attrs.orDefault";
      assertion = isAttrs default && isAttrs value;
      message = "expected attrsets, got default=${typeOf default} value=${typeOf value}";
      context = "evaluating attrs.orDefault";
    };
      if isNotEmpty' value
      then value
      else default;

  orEmpty = value:
    assert withContext {
      name = "attrs.orEmpty";
      assertion = isAttrs value && isNotEmpty' value;
      message = "expected an attrset or null, got ${typeOf value}";
      context = "evaluating attrs.orEmpty";
    };
      optionalAttrs (isNotEmpty' value) value;

  mergeUnique = {
    items,
    getAttrs,
    what ? "attributes",
    owner ? (name: name),
  }:
    foldl'
    (
      acc: name: let
        incoming = getAttrs name;
        collisions = filter (k: hasAttr k acc) (attrNames incoming);
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
    (attrNames items);

  getOrderedOr = {
    key,
    attrs,
    default ? null,
  }:
    if hasAttr key attrs
    then getAttr key attrs
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

  mapOrdered = {attrs}:
    mapAttrs (_: value: toOrdered {inherit value;}) attrs;

  parseOrdered = {value}: let
    ordered = toOrdered {inherit value;};

    primary = getOrderedOr {
      key = "1";
      attrs = ordered;
    };
    secondary = getOrderedOr {
      key = "2";
      attrs = ordered;
    };
    tertiary = getOrderedOr {
      key = "3";
      attrs = ordered;
    };

    preferred = primary;
    fallback = secondary;
    default =
      if isList value
      then
        nthOr {
          position = (length value) - 1;
          inherit value;
        }
      else value;
  in
    ordered
    // {inherit primary secondary tertiary preferred fallback default;};

  mapParsedOrdered = {attrs}:
    mapAttrs (_: value: parseOrdered {inherit value;}) attrs;
in
  exports
