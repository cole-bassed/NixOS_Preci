{
  bootstrap,
  inputs,
  ...
}: let
  inherit (bootstrap) attrsets config;
  inherit (config) getPackages;
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
in {
  inherit raw classified normalized;

  merged = classified // normalized;
  default = orEmpty normalized.nixpkgs;
}
