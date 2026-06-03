{src, ...}: let
  legacy = import ./imports src;

  custom = let
    name = src.names.lib;
    inherit (legacy.attrsets) recursiveUpdate optionalAttrs mapAttrs;
    inherit (legacy.lists) elem;

    mkLix = with scoped;
      includes:
        recursiveUpdate legacy (
          {inherit src;}
          // optionalAttrs (elem "api" includes) {inherit api;}
          // optionalAttrs (elem "attrsets" includes) {inherit attrsets;}
          // optionalAttrs (elem "config" includes) {inherit config;}
          // optionalAttrs (elem "debug" includes) {inherit debug;}
          // optionalAttrs (elem "filesystem" includes) {inherit filesystem;}
          // optionalAttrs (elem "lists" includes) {inherit lists;}
          // optionalAttrs (elem "modules" includes) {inherit modules;}
          // optionalAttrs (elem "options" includes) {inherit options;}
          // optionalAttrs (elem "strings" includes) {inherit strings;}
          // optionalAttrs (elem "types" includes) {inherit types;}
        );

    libraries = {
      api = import src.paths.api (mkLix [
        "attrsets"
        "modules"
        "lists"
      ]);
      attrsets = import ./attrsets.nix (mkLix [
        "debug"
        "lists"
        "types"
      ]);
      config = import ./config.nix (
        mkLix [
          "api"
          "debug"
          "modules"
          "filesystem"
          "lists"
          "types"
        ]
      );
      debug = import ./debug.nix (mkLix [
        "lists"
        "types"
      ]);
      filesystem = import ./filesystem.nix (mkLix [
        "debug"
        "lists"
      ]);
      lists = import ./lists.nix (mkLix [
        "debug"
        "types"
      ]);
      modules = import ./modules.nix (mkLix [
        "debug"
        "filesystem"
        "lists"
        "types"
      ]);
      options = import ./options.nix (mkLix [
        "debug"
        "lists"
        "types"
      ]);
      strings = import ./strings.nix (mkLix [
        "debug"
        "lists"
        "types"
      ]);
      types = import ./types.nix (mkLix [
        "debug"
      ]);
    };

    scoped = mapAttrs (_: value: (value.scoped or {}) // (value.global or {})) libraries;

    global = scoped.attrsets.mergeUnique {
      items = libraries;
      getAttrs = library: libraries.${library}.global or (libraries.${library} or {});
      what = "libraries";
      owner = library: "${name}.${library}.global";
    };
  in
    global // scoped;
in {
  lib = legacy;
  "${name}" = recursiveUpdate legacy custom;
}
