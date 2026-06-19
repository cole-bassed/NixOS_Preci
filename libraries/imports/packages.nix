{
  bootstrap,
  attrsets,
  excludes,
  ...
}: let
  exports = {
    scoped = {
      inherit classified normalized excluded getPackages;
      merged = classified // normalized;
      default = orEmpty normalized.nixpkgs;
    };
    global = {getFlakePackages = getPackages;};
  };
  excluded = excludes.packages or []; # TODO: Implement this
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
