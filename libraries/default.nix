{
  bootstrap ? import ./base,
  defaults ? {},
  flake ? {},
  name ? names.lib,
  names ? {
    src = "dots";
    lib = "lix";
    top = "_";
  },
  paths ? {src = ../.;},
}: let
  inherit (bootstrap.attrsets) update;
  external = import ./external {
    inherit bootstrap;
    flake =
      update {
        name = names.src;
        path = paths.src;
      }
      flake;
  };
  internal = import ./internal {inherit bootstrap external names defaults paths name;};
in
  {inherit bootstrap external internal;}
  // update external internal
