{
  bootstrap,
  defaults,
  inputs,
  ...
}: let
  inherit (bootstrap) attrsets config lists;
  inherit (config) preferDefault;
  inherit (lists) concat elem;
  inherit (attrsets) filter maps valuesOf;

  excludes = defaults.excludes.overlays or [];

  raw =
    filter
    (input: _: !(elem input excludes))
    inputs.classified.overlays;

  classified =
    filter
    (_: value: value != {})
    (maps (_: input: input.overlays or {}) raw);

  normalized = {};
in {
  inherit raw classified normalized excludes;

  merged =
    concat
    (map preferDefault (valuesOf (classified // normalized)));
}
