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
  internal = import ./internal {inherit external names defaults paths name;};
in
  {
    lib = external.libraries;
    "${name}" = internal;
  }
  // external
  // internal
