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
  internal = import ./internal {inherit external names defaults paths name;};
in
  {inherit bootstrap external internal;}
  // bootstrap.recursiveUpdate external internal
