{
  attrsets,
  lists,
  types,
  ...
}: let
  exports = {
    scoped = {inherit normalize resolve mkCfg select;};
    global = {
      registryOf = mkCfg;
      resolveRegistry = resolve;
      normalizeRegistry = normalize;
      selectionOf = select;
    };
  };

  inherit (attrsets) attrNames attrValues listToAttrs mapAttrs;
  inherit (lists) unique;
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

  rawOf = spec: let
    interface = spec.interface or {};
  in
    interface.backends
    or (
      unique (
        builtins.filter (x: x != null && x != "") (
          (interface.backend.managers or [])
          ++ (interface.backend.desktops or [])
          ++ [
            (interface.windowManager or null)
            (interface.desktopEnvironment or null)
          ]
        )
      )
    );

  select = {spec, ...}: let
    normalized = normalize (rawOf spec);
  in
    normalized;

  resolve = {
    spec,
    registry,
    top,
  }: let
    normalized = select {inherit spec registry top;};
    resolved = name: overrides:
      (registry.${name} or (throw "${top}.interface.resolve: '${name}' not in registry"))
      // overrides // {inherit name;};
  in
    attrValues (mapAttrs resolved normalized);

  mkCfg = {
    spec,
    registry,
    top,
  }:
    attrNames (select {inherit spec registry top;});
in
  exports
