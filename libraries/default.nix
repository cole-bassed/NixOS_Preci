{
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  shared = let
    # TODO: Create a version of mkSrc in the bootstrap, so that it's available at all levels.
    base =
      paths.store.libraries.shared or
      (paths.libraries.shared or
        (paths.shared or ./shared));
    seed = {inherit paths;};
  in
    (import base {inherit paths;}).mkLibrary {
      inherit base seed;
    };
  inherit (shared.seeded) mkLibrary recursiveAttrs removeAttrPaths;

  legacy = mkLibrary {
    base = ./import;
    seed = {
      inherit defaults flake names paths;
      bootstrap = shared.seeded;
      name = names.src or "dots";
      path = paths.store.src or (paths.src or ../.);
    };
  };

  custom = mkLibrary {
    base = ./custom;
    seed = let
      bootstrap = shared.seeded;
      external = legacy.seeded;
      flake' = external.seeded.flake or {};
    in
      recursiveAttrs
      (recursiveAttrs bootstrap external)
      {
        inherit bootstrap external;
        flake = flake';
        defaults = recursiveAttrs {
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
        } (recursiveAttrs defaults (flake'.defaults or {}));

        paths = recursiveAttrs {
          store = {
            src = ../.;
            api = ../configuration/api;
          };
          local.src = "/etc/nixos";
        } (recursiveAttrs paths (flake'.paths or {}));

        names = recursiveAttrs {
          src = "dots";
          lib = "lix";
          top = "_";
        } (recursiveAttrs names (flake'.names or {}));
      };
  };

  config = mkLibrary {
    seed = custom.seeded;
    base = ./config;
  };

  seeded = removeAttrPaths config.seeded [
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
in {
  inherit shared legacy custom config seeded;
  lib = legacy.seeded.nixpkgs;
  ${names.lib or "lix"} = seeded;
}
