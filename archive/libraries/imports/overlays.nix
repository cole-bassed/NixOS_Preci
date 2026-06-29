{
  bootstrap,
  attrsets,
  flake,
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
  inherit (attrsets) attrValues defaultOrAllValues filterAttrs mapAttrs;

  excluded = excludes.overlays or [];

  raw =
    filterAttrs
    (input: _: !(elem input excluded))
    inputs.classified.overlays;

  autoClassified =
    filterAttrs
    (_: value: value != {})
    (mapAttrs (_: input: input.overlays or {}) raw);

  autoNormalized =
    concatLists
    (map defaultOrAllValues (attrValues classified));

  registry = flake.registry or {};
  registryOverlays =
    registry.overlays or (
      if flake.overlays ? registry
      then builtins.mapAttrs (_: value: {inherit value;}) flake.overlays.registry
      else {}
    );

  classified =
    if registryOverlays != {}
    then builtins.mapAttrs (_: entry: {default = entry.value;}) registryOverlays
    else autoClassified;

  normalized =
    if registryOverlays != {}
    then map (entry: entry.value) (attrValues registryOverlays)
    else autoNormalized;
in
  exports
