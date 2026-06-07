{
  inputs ? {},
  root ? ../.,
  names ? {
    src = "dots";
    lib = "lix";
    top = "_";
  },
  defaults ? {allowUnfree = true;},
  name ? names.lib,
  paths,
}: let
  external = import ./external {inherit inputs defaults names paths root;};
  lib = external;
  internal = import ./internal {inherit external lib names defaults paths name;};
in
  {
    inherit lib;
    "${name}" = internal;
  }
  // lib
  // lib.inheritAttr "flake" external
  // internal
