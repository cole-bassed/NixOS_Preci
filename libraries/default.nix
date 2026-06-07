{
  inputs ? {},
  self ? {},
  defaults ? {},
  name ? names.lib,
  names,
  paths,
  ...
}: let
  external = import ./external {inherit inputs defaults self;};
  lib = external.libraries;
  inherit (lib) optionalAttrs isNotEmpty;
  internal = import ./internal {inherit external lib names defaults paths name;};
in
  {
    inherit lib;
    "${name}" = internal;
  }
  // lib
  // optionalAttrs (isNotEmpty external) {lib.flakes = lib.flakes // external;}
  // internal
