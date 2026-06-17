{
  attrsets,
  lists,
  strings,
  ...
}: let
  exports = {
    scoped = {inherit entrypoint entrypoints;};
    global = {inherit entrypoint entrypoints;};
  };

  # inherit (debug) withContext;
  inherit (lists) head;
  inherit (attrsets) mapAttrs;
  inherit (strings) stringLength substring;

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

  /**
  Maps a set of pure store paths into absolute local path strings relative to local.src
  */
  mapStoreToLocal = {
    store,
    localSrc,
  }: let
    storeRoot = toString store.src;
    rootLength = stringLength storeRoot;
  in
    mapAttrs (
      _: path: let
        pathStr = toString path;
        # Strip out the base store path prefix to capture the relative subpath
        relSubpath = substring rootLength (-1) pathStr;
      in "${localSrc}${relSubpath}"
    )
    store;
in
  exports
