{
  src,
  attrsets,
  lists,
  ...
}: let
  exports = {
    scoped = {inherit assemble entrypoint entrypoints;};
    global = {inherit entrypoint entrypoints;};
  };

  inherit (attrsets) attrValues filterAttrs mergeAttrsList;
  # inherit (debug) withContext;
  inherit (lists) head;

  assemble = spec:
    mergeAttrsList (
      map (path: import path src) (attrValues (filterAttrs (name: _: spec.${name} or false) src.paths))
    );

  entrypoints.nix = let
    ext = "nix";
    candidates = map (name: "${name}.${ext}") [
      "default"
      "shell"
      "flake"
      "configuration"
      "_"
    ];
    primary = head candidates;
  in {inherit ext candidates primary;};
  entrypoint = entrypoints.nix.primary;
in
  exports
