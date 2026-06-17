{
  defaults ? {},
  flake ? {},
  names ? {},
  paths ? {},
}: let
  bootstrap = import (
    paths.store.libraries.bootstrap or
      (paths.libraries.bootstrap or
        (paths.bootstrap or ./base))
  ) {inherit paths;};

  inherit (bootstrap.attrsets) merge;
  inherit (bootstrap.filesystem) mkPaths;
  inherit (bootstrap.config) mkLibrary;

  external = mkLibrary {
    base = ./external;
    excludes = ["default"];
    seed = {
      inherit bootstrap defaults flake names paths;
    };
    enableAliases = false;
    enableExtras = false;
  };

  internal = mkLibrary {
    base = ./internal;
    excludes = ["default" "base" "bootstrap"];
    seed =
      merge
      (merge bootstrap external)
      {
        inherit bootstrap external;
        flake = external.flake or {};
        defaults = merge defaults (
          merge {
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
          } (external.flake.defaults or {})
        );

        paths = mkPaths {
          paths = merge paths (
            merge {
              store = {
                src = ../.;
                api = ../configuration/api;
              };
              local.src = "/etc/nixos";
            } (external.flake.paths or {})
          );
        };

        names = merge names (
          merge {
            src = "dots";
            lib = "lix";
            top = "_";
          } (external.flake.names or {})
        );
      };
    extra = merge external bootstrap;
    enableAliases = false;
    enableExtras = false;
  };

  config = mkLibrary {
    base = ./config;
    excludes = ["default"];
    seed = internal;
    enableAliases = true;
    enableExtras = false;
  };
in {inherit bootstrap config external internal;}
