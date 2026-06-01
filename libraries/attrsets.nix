{
  lib,
  lists,
}: let
  exports = {
    internal = {
      inherit
        getOrderedOr
        toOrdered
        mapOrdered
        parseOrdered
        mapParsedOrdered
        mergeUnique
        ;
      orderedOf = toOrdered;
      parsedOf = parseOrdered;
      merge = mergeUnique;
    };
    external = {
      toOrderedAttrs = toOrdered;
      mapOrderedAttrs = mapOrdered;
      parseOrderedAttrs = parseOrdered;
      mapParsedOrderedAttrs = mapParsedOrdered;
      mergeUniqueAttrs = mergeUnique;
    };
  };

  inherit (lib.attrsets) hasAttr getAttr listToAttrs mapAttrs;
  inherit (lib.lists) genList isList length;
  inherit (lists) nthOr;

  mergeUnique = {
    items,
    getAttrs,
    what ? "attributes",
    owner ? (name: name),
  }: let
    inherit (lib.attrsets) attrNames hasAttr;
    inherit (lib.lists) filter foldl';
    inherit (lib.strings) concatStringsSep;
  in
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
