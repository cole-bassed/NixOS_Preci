{
  bootstrap ? import ./base,
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  inherit (bootstrap.attrsets) merge;

  external = import ./external {
    inherit bootstrap defaults flake names paths;
  };

  internal = import ./internal {inherit bootstrap external;};

  merged = merge external (merge bootstrap internal);
  # libraries =
  #   merged
  #   // {
  #     lib = merged.lib or external.${names.src}.libraries.merged;
  #     ${names.lib} = removeAttrs merged ["${merged.names.lib}"];
  #   };
in
  merged
  // {
    # lib = merged.lib or external.${names.src}.libraries.merged;
    # ${names.lib} = removeAttrs merged ["${merged.names.lib}"];
    # ${names.src} =
    #   (
    #     (external.${merged.names.src} or {})
    #     // (internal.${merged.names.src} or {})
    #   )
    #   // {libraries.merged = libraries;};
    # inherit (merged) defaults names paths;
  }
