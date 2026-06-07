{
  inputs ? {},
  root ? ../.,
  defaults ? {},
  name ? names.lib,
  names,
  paths,
}: let
  external = import ./external {inherit inputs defaults root;};
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
