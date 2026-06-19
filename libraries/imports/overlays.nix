{
  inputs,
  attrsets,
  modules,
  lists,
  excludes,
  ...
}: let
  inherit (modules) preferDefault;
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

  normalized = {};
in {
  inherit raw classified normalized excluded;

  merged =
    concatLists
    (map preferDefault (attrValues (classified // normalized)));
}
