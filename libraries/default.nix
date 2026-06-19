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
  inherit (shared.charged) mkLibrary recursiveUpdate removeAttrPaths;

  bootstrap =
    shared.charged
    // {
      flake =
        recursiveUpdate {
          name = bootstrap.names.src or bootstrap.defaults.names.src;
          path = bootstrap.paths.store.src or paths.src or ../.;
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
              "review" # TODO: Doesn't work at directory level
              "temp"
              "default"
              "default.nix" # TODO: Doesn't work
              "flake.nix"
            ]
            ++ (paths.excludes or [])
            ++ (bootstrap.defaults.excludes.paths or []);
        } (
          recursiveUpdate
          excludes
          (flake.excludes or (flake.defaults.excludes or {}))
        );

      paths = recursiveUpdate {
        excludes = bootstrap.excludes.paths;
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
          bootstrap = import base bootstrap;
        };
      excludes = bootstrap.excludes.paths;
    };
  flakes = with global.domains; {
    inherit overlays modules libraries packages inputs;
    enable = libraries.default.types.isFlakeLike inputs;
    nixpkgs = inputs.normalized.nixpkgs or {};
  };
  global' = recursiveUpdate global {
    charged.flake =
      recursiveUpdate
      (global.charged.flake or {})
      flakes;
    charged.flakes =
      recursiveUpdate
      (global.charged.flakes or {})
      (flakes // global.aliases);
    domains.libraries.merged.flakes =
      recursiveUpdate
      (global.domains.libraries.merged.flakes or {})
      (flakes // global.aliases);
    domains.libraries.default.flakes =
      recursiveUpdate
      (global.domains.libraries.default.flakes or {})
      (flakes // global.aliases);
  };

  custom = mkLibrary {
    base = ./custom;
    seed =
      recursiveUpdate
      global'.charged
      (
        recursiveUpdate
        global'.charged.libraries.default
        {inherit flakes;}
      );
  };

  cleaned = removeAttrPaths custom.charged [
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

  config = mkLibrary {
    seed = recursiveUpdate cleaned {
      lib = global.charged.libraries.merged;
      ${names.lib or "lix"} = cleaned;
    };
    base = ./config;
  };
  config' = recursiveUpdate global {
    charged.flake =
      recursiveUpdate
      (global.charged.flake or {})
      flakes;
    charged.flakes =
      recursiveUpdate
      (global.charged.flakes or {})
      (flakes // global.aliases);
    domains.libraries.merged.flakes =
      recursiveUpdate
      (global.domains.libraries.merged.flakes or {})
      (flakes // global.aliases);
    domains.libraries.default.flakes =
      recursiveUpdate
      (global.domains.libraries.default.flakes or {})
      (flakes // global.aliases);
  };

  merged = config'.charged;
in {
  inherit
    config
    custom
    shared
    merged
    ;
  global = global';
  lib = global.charged.libraries.merged;
  ${names.lib or "lix"} = merged;
}
