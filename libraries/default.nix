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

  charged =
    shared.charged
    // {
      flake =
        recursiveAttrs {
          name = charged.names.src or charged.defaults.names.src;
          path = charged.paths.store.src or paths.src or ../.;
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
              "review" # TODO: Doesn't work at directory level
              "temp"
              "default"
              "default.nix" # TODO: Doesn't work
              "flake.nix"
            ]
            ++ (paths.excludes or [])
            ++ (charged.defaults.excludes.paths or []);
        } (
          recursiveAttrs
          excludes
          (flake.excludes or (flake.defaults.excludes or {}))
        );

      paths = recursiveAttrs {
        excludes = charged.excludes.paths;
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
    base = ./imports;
    inputs = import (base + "/inputs.nix") charged;
    seed = charged // {inherit inputs;};
    excludes = charged.excludes.paths ++ ["inputs"];
  in
    mkLibrary {inherit base excludes seed;};
  # custom = mkLibrary {
  #   base = ./custom;
  #   seed = let
  #     bootstrap = shared.seeded;
  #     external = global.seeded;
  #     flake' = external.seeded.flake or {};
  #   in
  #     recursiveAttrs
  #     (recursiveAttrs bootstrap external)
  #     {
  #       inherit bootstrap external;
  #       flake = flake';
  #       defaults = recursiveAttrs {
  #         host = "ExampleHost";
  #         excludes.paths = [
  #           "archive"
  #           "backup"
  #           "review"
  #           "temp"
  #           "default.nix"
  #           "flake.nix"
  #         ];
  #         tags = ["core" "home"];
  #       } (recursiveAttrs defaults (flake'.defaults or {}));
  #       paths = recursiveAttrs {
  #         store = {
  #           src = ../.;
  #           api = ../configuration/api;
  #         };
  #         local.src = "/etc/nixos";
  #       } (recursiveAttrs paths (flake'.paths or {}));
  #       names = recursiveAttrs {
  #         src = "dots";
  #         lib = "lix";
  #         top = "_";
  #       } (recursiveAttrs names (flake'.names or {}));
  #     };
  # };
  # config = mkLibrary {
  #   seed = custom.seeded;
  #   base = ./config;
  # };
  # seeded = removeAttrPaths config.seeded [
  #   {
  #     scopes = [
  #       "lib"
  #       "lists"
  #       "modules"
  #     ];
  #     items = [
  #       "applyModuleArgsIfFunction"
  #       "collectModules"
  #       "dischargeProperties"
  #       "evalOptionValue"
  #       "fold"
  #       "isInOldestRelease"
  #       "mergeModules'"
  #       "mergeModules"
  #       "mkAliasOptionModuleMD"
  #       "mkFixStrictness"
  #       "nixpkgsVersion"
  #       "pushDownProperties"
  #       "unifyModuleSyntax"
  #     ];
  #   }
  # ];
in {
  inherit
    shared
    global
    # custom
    # config
    # seeded
    ;
  # lib = global.seeded.nixpkgs;
  # ${names.lib or "lix"} = seeded;
}
