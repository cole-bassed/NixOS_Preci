{flake ? {}, ...}: let
  names = {
    src = "dots";
    top = "dots";
    lib = "lix";
  };

  paths = {
    src = ./.;
    api = ./configuration/api;
    dbg = ./debug;
    documentation = ./documentation;
    configurations = ./configuration/modules;
    templates = ./templates;
    devShells = ./utilities/shells;
    utilities = ./utilities;
    secrets = ./configuration/secrets;
    libraries = ./libraries;
  };

  defaults =
    {
      # host = "example";
      # host = "ExampleHost";
      host = "Preci";
      excludes = [
        "archive"
        "backup"
        "review"
        "temp"
      ];

      tags = [
        "core"
        "home"
      ];
    }
    // (flake.defaults or {});

  libraries = import paths.libraries {
    inherit defaults paths names;
    inherit (flake) inputs root;
  };
  inherit (libraries) api;
in
  libraries.orEmptyAttrs libraries.flake
  // libraries.mkDots paths api.hosts.${defaults.host}
  // {
    inherit api defaults libraries names paths;
    "${names.lib}" = libraries;
  }
