{
  lib,
  defaults,
}: let
  inherit (lib.attrsets) recursiveUpdate optionalAttrs mapAttrs;

  mkLix = includes: {
    lix = recursiveUpdate legacy (with custom; (
      {inherit defaults;}
      // optionalAttrs (elem "attrsets" includes) {attrsets = with attrsets; external // internal;}
      // optionalAttrs (elem "lists" includes) {lists = with lists; external // internal;}
      // optionalAttrs (elem "modules" includes) {modules = with modules; external // internal;}
      // optionalAttrs (elem "options" includes) {options = with options; external // internal;}
      // optionalAttrs (elem "strings" includes) {strings = with strings; external // internal;}
      // optionalAttrs (elem "system" includes) {system = with system; external // internal;}
      // optionalAttrs (elem "types" includes) {types = with types; external // internal;}
    ));
  };

  legacy = import ./nixpkgs.nix {inherit lib;};
  custom = {
    attrsets = import ./attrsets.nix (mkLix ["debug" "lists" "types"]);
    debug = import ./debug.nix (mkLix ["lists" "types"]);
    lists = import ./lists.nix (mkLix ["debug" "types"]);
    modules = import ./modules.nix (mkLix ["debug" "lists" "types"]);
    options = import ./options.nix (mkLix ["debug" "lists" "types"]);
    strings = import ./strings.nix (mkLix ["debug" "lists" "types"]);
    system = import ./system.nix (mkLix ["debug" "types"]);
    types = import ./types.nix (mkLix ["debug"]);
  };
in
  ( #~@ Flat - lix.*
    custom.attrsets.merge {
      items = custom;
      getAttrs = name: custom.${name}.external or {};
      what = "libraries: external aliases";
    }
  )
  // ( #~@ Namespaced lix.<name>.*
    mapAttrs (_: lib: lib.internal) custom
  )
