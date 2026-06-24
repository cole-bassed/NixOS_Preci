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
      } (recursiveUpdate paths flake.paths or {});

      names = recursiveUpdate {
        src = "dots";
        lib = "lix";
      } (recursiveUpdate names (flake.names or {}));
    };
    assembly = import (base + "/assembly.nix") seed;
    inherit (assembly.global) mkLibrary;
  in
    mkLibrary {inherit base seed;};
  inherit (shared.charged) mkLibrary recursiveUpdate;

  global = let
    base =
      paths.store.libraries.global or
    (paths.libraries.global or
      (paths.global or ./imports));

    built = mkLibrary {
      inherit base;
      seed =
        shared.charged
        // {bootstrap = import base shared.charged;}
        // {staged = shared;};
    };

    stripped = let
      lib = built.domains.libraries.default;
      charged =
        (
          recursiveUpdate
          (removeAttrs built.charged ["bootstrap"])
          built.domains.libraries.default
        )
        // {inherit lib;};
    in
      built
      // {
        inherit charged lib;
        ${names.lib or "lix"} = charged;
      };

    updated = recursiveUpdate stripped (let
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
        (stripped.charged.flake or {})
        flakeArgs;

      charged.flakes =
        recursiveUpdate
        (stripped.charged.flakes or {})
        flakeLibs;

      domains.libraries.merged.flakes =
        recursiveUpdate
        (stripped.lib.flakes or {})
        flakeLibs;

      domains.libraries.default.flakes =
        recursiveUpdate
        (stripped.charged.flakes or {})
        flakeLibs;
    });
  in
    updated;

  custom = let
    base = mkLibrary {
      base = ./custom;
      seed = global.charged // {staged = global;};
    };

    charged = base.charged // {pathsResolved = base.charged.mkPaths {};};
    updated =
      base
      // {
        inherit charged;
        ${names.lib or "lix"} = charged;
      };
  in
    updated;

  config = mkLibrary {
    seed = custom.charged // {staged = custom;};
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
  inherit (merged) lib;
  ${names.lib or "lix"} = merged;
}
