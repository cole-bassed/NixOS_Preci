{
  bootstrap ? import ./bootstrap.nix,
  defaults ? {allowUnfree = true;},
  inputs ? {},
  name ? names.lib,
  names ? {
    src = "dots";
    lib = "lix";
    top = "_";
  },
  paths ? {src = ../.;},
  root ? paths.src,
}: let
  external = import ./external {inherit bootstrap inputs defaults names paths root;};
  lib = external;
  internal = import ./internal {inherit external lib names defaults paths name;};
in
  {
    inherit lib;
    "${name}" = internal;
  }
  // bootstrap
  // lib
  // lib.inheritAttr "flake" external
  // internal
