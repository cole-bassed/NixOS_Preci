{
  attrsets,
  types,
  ...
}: let
  exports = {
    scoped = {inherit normalize resolve mkCfg;};
    global = {
      registryOf = mkCfg;
      resolveRegistry = resolve;
      normalizeRegistry = normalize;
    };
  };

  inherit (attrsets) attrValues listToAttrs mapAttrs;
  inherit (types) isList;

  normalize = raw:
    if isList raw
    then
      listToAttrs (map (name: {
          inherit name;
          value = {};
        })
        raw)
    else raw;

  resolve = {
    spec,
    registry,
    top,
  }: let
    ctx = "${top}.interface.resolve";
    raw = (spec.interface or {}).backends or [];
    normalized = normalize raw;
    resolved = name: overrides:
      (registry.${name} or (throw "${ctx}: '${name}' not in registry"))
      // overrides // {inherit name;};
  in
    attrValues (mapAttrs resolved normalized);

  mkCfg = {
    spec,
    registry,
    top,
  }:
    map
    (entry: entry.name)
    (resolve {inherit spec registry top;});
in
  exports
