{
  lib,
  defaults,
}: let
  inherit
    (lib.attrsets)
    recursiveUpdate
    optionalAttrs
    mapAttrs
    ;
  mkLix = includes: let
  in
    recursiveUpdate legacy (with custom; (
      {inherit defaults;}
      // optionalAttrs (elem "attrsets" includes) {attrsets = with attrsets; external // internal;}
      // optionalAttrs (elem "lists" includes) {lists = with lists; external // internal;}
      // optionalAttrs (elem "modules" includes) {modules = with modules; external // internal;}
      // optionalAttrs (elem "options" includes) {options = with options; external // internal;}
      // optionalAttrs (elem "strings" includes) {strings = with strings; external // internal;}
      // optionalAttrs (elem "system" includes) {system = with system; external // internal;}
      // optionalAttrs (elem "types" includes) {types = with types; external // internal;}
    ));

  legacy = import ./nixpkgs.nix {inherit lib;};
  custom = {
    debug = import ./debug.nix {lix = mkLix ["lists" "types"];};
    lists = import ./lists.nix {lix = mkLix [];};
    system = import ./system.nix {lix = mkLix [];};
    types = import ./types.nix {lix = mkLix ["debug"];};
    options = import ./options.nix {lix = mkLix ["debug" "lists" "types"];};
    strings = import ./strings.nix {lix = mkLix ["debug" "lists" "types"];};
    attrsets = import ./attrsets.nix {lix = mkLix ["debug" "lists" "types"];};
    modules = import ./modules.nix {lix = mkLix ["debug" "lists" "types"];};
  };

  inherit (custom.attrsets) merge;
in
  ( #~@ Flat - lix.*
    merge {
      items = custom;
      getAttrs = name: custom.${name}.external or {};
      what = "libraries: external aliases";
    }
  )
  // ( #~@ Namespaced lix.<name>.*
    mapAttrs (_: lib: lib.internal) custom
  )
