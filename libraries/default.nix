{
  defaults ? {},
  flake ? {},
  names ? {},
  excludes ? {},
  paths ? {},
}: let
  # TODO: Create a version of mkSrc in base, so that it's available at all levels.
  shared = let
    base =
      paths.store.libraries.shared or
      (paths.libraries.shared or
        (paths.shared or ./base));
    inherit (import base) recursiveUpdate;
    seed = {
      flake =
        recursiveUpdate {
          name = seed.names.src or seed.defaults.names.src;
          path = seed.paths.store.src or paths.src or ../.;
        }
        flake;

      defaults = recursiveUpdate {
        host = "ExampleHost";
        tags = ["core" "home"];
      } (recursiveUpdate defaults (flake.defaults or {}));

      excludes =
        recursiveUpdate {
          paths =
            [
              "archive"
              "backup"
              "bootstrap"
              "review"
              "temp"
              "default"
              "default.nix"
              "flake.nix"
            ]
            ++ (paths.excludes or [])
            ++ (seed.defaults.excludes.paths or []);
        } (
          recursiveUpdate
          excludes
          (flake.excludes or (flake.defaults.excludes or {}))
        );

      paths = recursiveUpdate {
        excludes = seed.excludes.paths;
        store = {
          src = ../.;
          api = ../configuration/api;
        };
        local.src = "/etc/nixos";
      } (recursiveUpdate paths (flake.paths or {}));

      names = recursiveUpdate {
        src = "dots";
        lib = "lix";
        top = "_";
      } (recursiveUpdate names (flake.names or {}));
    };
    assembly = import (base + "/assembly.nix") seed;
    inherit (assembly.global) mkLibrary;
  in
    mkLibrary {inherit base seed;};
  inherit (shared.charged) mkLibrary recursiveUpdate removeAttrPaths;

  global = let
    base =
      paths.store.libraries.global or
    (paths.libraries.global or
      (paths.global or ./imports));

    built = mkLibrary {
      inherit base;
      seed = shared.charged // {bootstrap = import base shared.charged;};
    };

    stripped = let
      lib = built.domains.libraries.default;
      charged =
        recursiveUpdate
        (removeAttrs built.charged ["bootstrap"])
        lib;
    in
      charged
      // {
        inherit lib;
        ${names.lib or "lix"} = charged;
      };

    flaked = recursiveUpdate stripped (let
      flakeArgs =
        built.domains
        // (with built.domains; {
          enable = libraries.default.types.isFlakeLike inputs;
          nixpkgs = inputs.normalized.nixpkgs or {};
        });

      flakeLibs = recursiveUpdate flakeArgs built.aliases;
    in {
      charged.flake =
        recursiveUpdate
        (built.charged.flake or {})
        flakeArgs;

      charged.flakes =
        recursiveUpdate
        (built.charged.flakes or {})
        flakeLibs;

      domains.libraries.merged.flakes =
        recursiveUpdate
        (built.domains.libraries.merged.flakes or {})
        flakeLibs;

      domains.libraries.default.flakes =
        recursiveUpdate
        (built.domains.libraries.default.flakes or {})
        flakeLibs;
    });

    cleaned = removeAttrPaths flaked [
      {
        scopes = [
          "lib"
          "lists"
          "modules"
        ];
        items = [
          "applyModuleArgsIfFunction"
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
  in
    cleaned;

  custom = mkLibrary {
    base = ./custom;
    seed = global.charged;
  };

  config = mkLibrary {
    seed = custom.charged;
    base = ./config;
  };

  merged = config.charged;
in {
  inherit
    config
    custom
    shared
    merged
    global
    ;
  inherit (global) lib;
  ${names.lib or "lix"} = merged;
}
