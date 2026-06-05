{
  defaults,
  external,
  flake,
  name ? names.lib,
  names,
  paths,
  ...
}: let
  inherit (external.attrsets) recursiveUpdate optionalAttrs mapAttrs;
  inherit (external.lists) elem;

  scoped =
    mapAttrs (
      name: library: (library.scoped or {}) // (library.global or {})
    )
    libraries;

  global = scoped.attrsets.mergeUnique {
    owner = library: "${name}.${library}.global";
    what = "libraries";
    items = libraries;
    attrs = library:
      libraries.${library}.global or (libraries.${library} or {});
  };

  mkLib = with scoped;
    includes:
      recursiveUpdate external (
        {inherit flake names defaults paths;}
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
    api = import paths.api (mkLib [
      "attrsets"
      "modules"
      "lists"
    ]);
    attrsets = import ./attrsets.nix (mkLib [
      "debug"
      "lists"
      "types"
    ]);
    config = import ./config.nix (mkLib [
      "api"
      "debug"
      "modules"
      "filesystem"
      "lists"
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
    modules = import ./modules.nix (mkLib [
      "debug"
      "filesystem"
      "lists"
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
in
  global
  // scoped
  // {inherit global scoped;}
