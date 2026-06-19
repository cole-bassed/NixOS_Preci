{
  bootstrap,
  attrsets,
  lists,
  excludes,
  ...
}: let
  exports = {
    scoped = {inherit classified normalized excluded;};
    global = {flakes.overlays = normalized;};
  };

  inherit (bootstrap) inputs preferDefault;
  inherit (lists) concatLists elem;
  inherit (attrsets) filterAttrs mapAttrs attrValues;

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
    (map preferDefault (attrValues classified));
in
  exports
