{
  bootstrap ? import ../base,
  external ? import ../external {},
  defaults ? {},
  names ? {},
  paths ? {},
  ...
}: let
  inherit (bootstrap.attrsets) gets orEmpty' maps update;
  name = args.names.lib;
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
  };

  scoped =
    maps
    (_: library: (library.scoped or {}) // (library.global or {}))
    libraries;

  global = scoped.attrsets.mergeUnique {
    owner = library: "${name}.${library}.global";
    what = "libraries";
    items = libraries;
    attrs = library:
      libraries.${library}.global or (libraries.${library} or {});
  };

  base =
    update
    (update bootstrap external)
    {inherit defaults names paths;};

  all = external.classified;

  default = update base (
    global
    // scoped
    // {
      lib = base;

      "${name}" = update external (
        global
        // scoped
        // {
          inherit global scoped;
        }
      );
    }
  );

  mkLib = includes:
    update base (
      {libraries = all;}
      // orEmpty' "flake" external
      // gets includes scoped
    );

  libraries = {
    api = import paths.api (mkLib [
      "attrsets"
      "modules"
      "lists"
    ]);

    attrsets = import ./attrsets.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    config = import ./config.nix (mkLib [
      "api"
      "debug"
      "modules"
      "filesystem"
      "lists"
      "types"
    ]);

    debug = import ./debug.nix (mkLib [
      "lists"
      "types"
    ]);

    filesystem = import ./filesystem.nix (mkLib [
      "debug"
      "lists"
    ]);

    lists = import ./lists.nix (mkLib [
      "debug"
      "types"
    ]);

    modules = import ./modules.nix (mkLib [
      "debug"
      "filesystem"
      "lists"
      "types"
    ]);

    options = import ./options.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    strings = import ./strings.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    types = import ./types.nix (mkLib [
      "debug"
    ]);
  };
in
  default
