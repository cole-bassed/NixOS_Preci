{
  bootstrap ? import ./base,
  external ? import ../external {},
  paths,
  defaults,
  names,
}: let
  inherit (bootstrap.attrsets) maps merge;
  inherit (bootstrap.config) mkLib;

  flake = external.flake or {};
  name = args.names.lib;

  args = {
    inherit bootstrap;
    defaults = merge (merge defaults {
      host = "TheExample";
      excludes = {
        paths = [
          "archive"
          "backup"
          "review"
          "temp"
          "default.nix"
          "flake.nix"
        ];
      };
      tags = ["core" "home"];
    }) (flake.defaults or {});

    paths = merge paths (merge {
      store = {
        src = ../../.;
        api = ../../configuration/api;
      };
      local.src = "/etc/nixos";
    } (flake.paths or {}));

    names = merge names (merge {
      src = "dots";
      lib = "lix";
      top = "_";
    } (flake.names or {}));
  };

  base =
    merge
    (merge external bootstrap)
    {
      inherit (args) defaults names paths;
      inherit flake libraries external mkLib;
    };

  libraries = {
    api = import args.paths.store.api (mkLib [
      "attrsets"
      "config"
      "lists"
    ]);

    attrsets = import ./attrsets.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    config = import ./config (mkLib [
      "api"
      "attrsets"
      "debug"
      "environment"
      "filesystem"
      "lists"
      "modules"
      "strings"
      "system"
      "types"
    ]);

    debug = import ./debug.nix (mkLib [
      "lists"
      "types"
    ]);

    filesystem = import ./filesystem.nix (mkLib [
      "debug"
      "lists"
    ]);

    lists = import ./lists.nix (mkLib [
      "debug"
      "types"
    ]);

    options = import ./options.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    strings = import ./strings.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);

    types = import ./types.nix (mkLib [
      "debug"
    ]);
  };

  scoped = maps (_: library: library.scoped or {}) libraries;
  global = maps (_: library: library.global or {}) libraries;
in
  merge base (
    global
    // scoped
    // {
      lib = external;

      "${name}" = merge external (
        global
        // scoped
        // {inherit global scoped;}
      );
    }
  )
