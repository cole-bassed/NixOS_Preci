{
  bootstrap ? import ./base,
  defaults ? {},
  inputs ? {},
  names ? {},
  paths ? {src = ../.;},
}: let
  inherit (bootstrap.attrsets) update;

  args = {
    inherit bootstrap inputs;
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
  };

  external = import ./external {
    inherit (args) bootstrap defaults inputs names paths;
  };

  internal = import ./internal {inherit bootstrap external;};
in (
  update external (update bootstrap internal)
  // {inherit bootstrap external internal;}
)
