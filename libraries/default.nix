{
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  bootstrap = import (
    paths.store.libraries.bootstrap or
      (paths.libraries.bootstrap or
        (paths.bootstrap or ./internal/base))
  ) {inherit paths;};

  external = import (
    paths.store.libraries.external or
      (paths.libraries.external or
        (paths.external or ./external))
  ) {inherit bootstrap defaults flake names paths;};

  internal =
    import (
      paths.store.libraries.internal or
      (paths.libraries.internal or
        (paths.internal or ./internal/base))
    ) {
      inherit bootstrap external;
      inherit (external) flake defaults names paths;
    };
in {inherit bootstrap external internal;}
