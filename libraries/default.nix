{
  inputs ? {},
  self ? {},
  defaults ? {},
  name ? names.lib,
  names,
  paths,
  ...
}: let
  lib = external.libraries;
  inherit (lib) asAttrsIf isNotEmpty;
  external = import ./external {inherit inputs defaults self;};
  internal = import ./internal {inherit external lib names defaults paths name;};
in
  {
    inherit lib;
    "${name}" = internal;
  }
  # // (asAttrsIf (isNotEmpty external) {inherit external;})
  // (asAttrsIf (isNotEmpty external) external)
  // lib
  // internal
