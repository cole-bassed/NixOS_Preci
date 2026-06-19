{
  bootstrap,
  attrsets,
  lists,
  excludes,
  ...
}: let
  exports = {
    scoped = {
      inherit classified normalized excluded;
      all = classified // normalized;
      default = normalized;
    };
    # global = {flakes.overlays = normalized;};
  };

  inherit (bootstrap) inputs preferDefaultModules;
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
    (map preferDefaultModules (attrValues classified));
in
  exports
