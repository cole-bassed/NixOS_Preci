{
  external ? null,
  bootstrap ? null,
  flake ? {},
  paths ? {},
  defaults ? {},
  names ? {},
}: let
  bootstrap' =
    if bootstrap != null
    then bootstrap
    else
      import (
        paths.store.libraries.bootstrap or (
          paths.libraries.bootstrap or (
            paths.bootstrap or ../internal/base
          )
        )
      );

  external' =
    if external != null
    then external
    else
      import (
        paths.store.libraries.external or (
          paths.libraries.external or (
            paths.external or ../external
          )
        )
      ) {inherit defaults flake names paths;};
  flake' = external'.flake or flake;

  inherit (bootstrap'.attrsets) merge;
  inherit (bootstrap'.config) mkLibrary mkPaths;

  seed =
    merge
    (merge external' bootstrap')
    {
      bootstrap = bootstrap';
      external = external';
      flake = flake';

      defaults = merge defaults (
        merge {
          host = "ExampleHost";
          excludes.paths = [
            "archive"
            "backup"
            "review"
            "temp"
            "default.nix"
            "flake.nix"
          ];
          tags = ["core" "home"];
        }
        (flake'.defaults or {})
      );

      paths = mkPaths {
        paths = merge paths (
          merge {
            store = {
              src = ../../.;
              api = ../../configuration/api;
            };
            local.src = "/etc/nixos";
          }
          (flake'.paths or {})
        );
      };

      names = merge names (
        merge {
          src = "dots";
          lib = "lix";
          top = "_";
        }
        (flake'.names or {})
      );
    };

  excludes = ["default" "base" "bootstrap"];
  extra = merge external' bootstrap';
in
  mkLibrary {
    inherit seed excludes extra;
    base = ./.;
    enableAliases = false;
    enableExtras = false;
  }
