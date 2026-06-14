{
  bootstrap ? import ./base,
  external ? import ../external {},
  paths,
  defaults,
  names,
}: let
  inherit (bootstrap.attrsets) merge gets;
  inherit (bootstrap.config) mkLib mkLibs;

  fix = fn: let set = fn set; in set;

  resolved = {
    flake = external.flake or {};

    defaults =
      merge
      (merge defaults {
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
      })
      (resolved.flake.defaults or {});

    paths =
      merge
      paths
      (merge {
        store = {
          src = ../../.;
          api = ../../configuration/api;
        };
        local.src = "/etc/nixos";
      })
      (resolved.flake.paths or {});

    names =
      merge
      names
      (merge {
        src = "dots";
        lib = "lix";
        top = "_";
      })
      (resolved.flake.names or {});
    name = resolved.names.lib;
  };

  mkLib' = {
    libraries,
    input,
    dependencies ? [],
    output ? [],
  }:
    mkLib {
      inherit input output;
      args =
        (
          merge
          (merge external bootstrap)
          {inherit (resolved) defaults names paths external flake;}
        )
        // (gets dependencies libraries);
    };

  libraries = fix (
    libraries: let
      mk = {
        input,
        dependencies ? [],
        output ? [],
      }:
        mkLib' {inherit input output dependencies libraries;};
    in
      {}
      // mk {
        input = resolved.paths.store.api;
        dependencies = ["attrsets" "config" "lists"];
      }
      // mk {
        input = ./attrsets.nix;
        dependencies = ["debug" "lists" "types"];
      }
      // mk {
        input = ./debug.nix;
        dependencies = ["lists" "types"];
      }
      // mk {
        input = ./filesystem.nix;
        dependencies = ["debug" "lists"];
      }
      // mk {
        input = ./lists.nix;
        dependencies = ["debug" "types"];
      }
      // mk {
        input = ./options.nix;
        dependencies = ["debug" "lists" "types"];
      }
      // mk {
        input = ./strings.nix;
        dependencies = ["debug" "lists" "types"];
      }
      // mk {
        input = ./types.nix;
        dependencies = ["debug"];
      }
      // (import ./config {
        inherit libraries mkLibs;
      })
  );

  legacy = external;
  global = merge legacy libraries;
in
  merge global {
    lib = legacy;
    "${resolved.name}" = global;
  }
