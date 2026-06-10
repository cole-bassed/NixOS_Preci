{
  bootstrap ? import ./base,
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  inherit (bootstrap.attrsets) merge;

  args = {
    inherit bootstrap flake;
    defaults =
      merge {
        excludes = {
          paths = [
            "archive"
            "backup"
            "review"
            "temp"

            "default.nix"
            "flake.nix"
          ];
        };

        tags = ["core" "home"];
      }
      defaults;

    paths =
      merge {
        store = {
          src = ../.;
          api = ../configuration/api;
        };
      }
      paths;

    names =
      merge {
        src = "dots";
        lib = "lix";
        top = "_";
      }
      names;
  };

  external = import ./external {
    inherit (args) bootstrap defaults flake names paths;
  };
  # internal = import ./internal {inherit bootstrap external;};
  internal = {};
  merged = merge external (merge bootstrap internal);
in {
  lib = external.${names.src}.libraries.merged;
  ${names.src} = (external.${names.src} or {}) // (internal.${names.src} or {});
  ${names.lib} = removeAttrs merged ["${names.lib}"];
}
