{
  bootstrap ? import ./internal/base,
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  inherit (bootstrap.attrsets) merge;

  external = import ./external {
    inherit bootstrap defaults flake names paths;
  };

  internal = import ./internal {
    inherit bootstrap defaults external names paths;
  };
in
  merge external internal
