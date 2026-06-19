{
  defaults ? {},
  flake ? {},
  names ? {},
  excludes ? {},
  paths ? {},
}: let
  shared = let
    # TODO: Create a version of mkSrc in the bootstrap, so that it's available at all levels.
    base =
      paths.store.libraries.shared or
      (paths.libraries.shared or
        (paths.shared or ./base));
  in
    (import base).mkLibrary {inherit base;};
  inherit (shared.charged) mkLibrary recursiveAttrs removeAttrPaths;

  bootstrap =
    shared.charged
    // {
      flake =
        recursiveAttrs {
          name = bootstrap.names.src or bootstrap.defaults.names.src;
          path = bootstrap.paths.store.src or paths.src or ../.;
        }
        flake;

      defaults = recursiveAttrs {
        host = "ExampleHost";
        tags = ["core" "home"];
      } (recursiveAttrs defaults (flake.defaults or {}));

      excludes =
        recursiveAttrs {
          paths =
            [
              "archive"
              "backup"
              "bootstrap"
              "review" # TODO: Doesn't work at directory level
              "temp"
              "default"
              "default.nix" # TODO: Doesn't work
              "flake.nix"
            ]
            ++ (paths.excludes or [])
            ++ (bootstrap.defaults.excludes.paths or []);
        } (
          recursiveAttrs
          excludes
          (flake.excludes or (flake.defaults.excludes or {}))
        );

      paths = recursiveAttrs {
        excludes = bootstrap.excludes.paths;
        store = {
          src = ../.;
          api = ../configuration/api;
        };
        local.src = "/etc/nixos";
      } (recursiveAttrs paths (flake.paths or {}));

      names = recursiveAttrs {
        src = "dots";
        lib = "lix";
        top = "_";
      } (recursiveAttrs names (flake.names or {}));
    };

  global = let
    base = paths.store.libraries.global or
      (paths.libraries.global or
        (paths.global or ./imports));
  in
    mkLibrary {
      inherit base;
      seed =
        bootstrap
        // {
          bootstrap = import (base + "/bootstrap.nix") bootstrap;
        };
      excludes = bootstrap.excludes.paths;
    };
  flakes = with global.domains; {
    inherit overlays modules libraries packages inputs;
    args = flake // {enable = libraries.default.types.isFlakeLike inputs;};
  };

  custom = mkLibrary {
    base = ./custom;
    seed =
      recursiveAttrs
      global.charged
      (
        recursiveAttrs
        global.charged.libraries.default
        {inherit flakes;}
      );
  };
  config = mkLibrary {
    seed = custom.charged // {bootstrap = custom.charged;};
    base = ./config;
  };

  charged = removeAttrPaths config.charged [
    {
      scopes = [
        "lib"
        "lists"
        "modules"
      ];
      items = [
        "applyModuleArgsIfFunction"
        "bootstrap"
        "collectModules"
        "dischargeProperties"
        "evalOptionValue"
        "fold"
        "isInOldestRelease"
        "mergeModules'"
        "mergeModules"
        "mkAliasOptionModuleMD"
        "mkFixStrictness"
        "nixpkgsVersion"
        "pushDownProperties"
        "unifyModuleSyntax"
      ];
    }
  ];
in {
  inherit
    shared
    global
    custom
    config
    charged
    ;
  flake = flakes;
  # lib = global.seeded.nixpkgs;
  # ${names.lib or "lix"} = seeded;
}
