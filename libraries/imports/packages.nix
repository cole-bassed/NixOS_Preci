{
  bootstrap,
  attrsets,
  excludes,
  ...
}: let
  exports = {
    scoped = {
      inherit classified normalized excluded;
      all = classified // normalized;
      default = orEmpty normalized.nixpkgs;
    };
    global = {flakes.packages = normalized;};
  };
  excluded = excludes.packages or []; # TODO: Incorporate this
  inherit (bootstrap) inputs getPackages;
  inherit (attrsets) asIf maps orEmpty;

  raw = inputs.classified.packages;

  classified =
    maps
    (_: getPackages)
    raw;

  normalized =
    asIf (inputs.normalized.nixpkgs != null) {
      nixpkgs = getPackages inputs.normalized.nixpkgs;
    }
    // asIf (inputs.normalized.home-manager != null) {
      home-manager = getPackages inputs.normalized.home-manager;
    };
in
  exports
