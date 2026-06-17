{
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  bootstrap = let
    base =
      paths.store.libraries.bootstrap or
      (paths.libraries.bootstrap or
        (paths.bootstrap or ./base));
    lib = import base {inherit paths;};
  in
    lib.mkLibrary {
      inherit base;
      excludes = ["default" "bootstrap"];
      seed = {inherit paths;};
      enableAliases = true;
      enableExtras = true;
    };
  inherit (bootstrap.assembly) mkLibrary;
  inherit (bootstrap.trivial) recursiveSelf;
  inherit (bootstrap.attrsets) recursiveAttrs removePaths;

  external = mkLibrary {
    base = ./external;
    seed = {
      inherit bootstrap defaults flake names paths;
      name = names.src or "dots";
      path = paths.store.src or (paths.src or ../.);
    };
    enableAliases = true;
    enableExtras = true;
  };

  seed =
    recursiveAttrs
    (recursiveAttrs bootstrap external)
    {
      inherit bootstrap external recursiveAttrs;
      flake = external.flake or {};

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
      } (recursiveAttrs defaults (external.flake.defaults or {}));

      paths = recursiveAttrs {
        store = {
          src = ../.;
          api = ../configuration/api;
        };
        local.src = "/etc/nixos";
      } (recursiveAttrs paths (external.flake.paths or {}));

      names = recursiveAttrs {
        src = "dots";
        lib = "lix";
        top = "_";
      } (recursiveAttrs names (external.flake.names or {}));
    };

  internal = let
  in
    mkLibrary {
      seed = seed // {_ = seed;};
      base = ./internal;
      excludes = ["default" "base" "bootstrap"];
      extra = {inherit (seed) defaults paths names flake;};
      enableAliases = true;
      enableExtras = true;
    };

  curated = recursiveAttrs seed internal;
  configuration = recursiveSelf (
    self: let
      seed = recursiveAttrs curated {
        inherit api;
      };

      config = mkLibrary {
        seed = seed // {_ = seed;};
        base = ./config;
        excludes = ["default"];
        extra = {};
        enableAliases = true;
        enableExtras = true;
      };

      api = import (
        seed.paths.store.api or (
          paths.store.api or (
            paths.api or ../configuration/api
          )
        )
      ) (recursiveAttrs seed config);
    in
      recursiveAttrs config {
        inherit api;
      }
  );
  # configuration = let
  #   api =
  #     import (
  #       curated.paths.store.api or (
  #         paths.store.api or (
  #           paths.api or ../configuration/api
  #         )
  #       )
  #     )
  #     curated;

  #   seed = recursiveAttrs curated {inherit api;};
  #   config = mkLibrary {
  #     inherit seed;
  #     base = ./config;
  #     excludes = ["default"];
  #     extra = {};
  #     enableAliases = true;
  #     enableExtras = true;
  #   };
  # in
  #   recursiveAttrs config {inherit api;};

  # configuration = recursiveSelf (self: let
  #   seed = recursiveAttrs curated self;
  # in
  #   recursiveAttrs (mkLibrary {
  #     inherit seed;
  #     base = ./config;
  #     excludes = ["default"];
  #     # extra = {inherit (bootstrap) trivial assembly;};
  #     enableAliases = true;
  #     enableExtras = true;
  #   }) {
  #     api =
  #       import (
  #         seed.paths.store.api or (
  #           paths.store.api or (
  #             paths.api or ../configuration/api
  #           )
  #         )
  #       )
  #       seed;
  #   });

  libraries =
    removePaths (
      recursiveAttrs bootstrap (
        recursiveAttrs external (
          recursiveAttrs internal configuration
        )
      )
    ) [
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
  inherit seed;
  inherit bootstrap external internal configuration;
  lib = external.libraries.nixpkgs;
  ${seed.names.lib or names.lib or "lib"} = libraries;
}
