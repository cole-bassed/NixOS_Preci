{
  bootstrap ? import ./base,
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {src = ../.;},
}: let
  inherit (bootstrap.attrsets) update;

  args = {
    inherit bootstrap;
    defaults =
      update {
        host = "ExampleHost";
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
      update {
        src = ../.;
        api = ../configuration/api;
      }
      paths;

    names =
      update {
        src = "dots";
        lib = "lix";
        top = "_";
      }
      names;

    flake =
      update {
        name = args.names.src;
        path = args.paths.src;
      }
      flake;

    external = import ./external {
      inherit (args) bootstrap flake;
    };

    internal = import ./internal {
      inherit (args) bootstrap defaults external names paths;
    };
  };
in (
  with args;
    update (update bootstrap external) internal
    // {inherit bootstrap external internal;}
)
