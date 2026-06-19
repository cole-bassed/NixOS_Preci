{
  bootstrap,
  attrsets,
  lists,
  excludes,
  ...
}: let
  exports = {
    scoped = {
      inherit classified normalized excluded hasOverlays;
      merged = classified // normalized;
      default = normalized;
    };
    global = {inherit hasOverlays;};
  };

  inherit (bootstrap) hasOverlays inputs;
  inherit (lists) concatLists elem;
  inherit (attrsets) defaultOrAllValues filterAttrs mapAttrs attrValues;

  excluded = excludes.overlays or [];

  raw =
    filterAttrs
    (input: _: !(elem input excluded))
    inputs.classified.overlays;

  classified =
    filterAttrs
    (_: value: value != {})
    (mapAttrs (_: input: input.overlays or {}) raw);

  normalized =
    concatLists
    (map defaultOrAllValues (attrValues classified));
in
  exports
