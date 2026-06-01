{
  lib,
  defaults,
}: let
  inherit (lib.attrsets) recursiveUpdate optionalAttrs mapAttrs;
  inherit (lib.lists) elem;

  mkLix = includes: {
    lix = recursiveUpdate legacy (with custom; (
      {inherit defaults;}
      // optionalAttrs (elem "attrsets" includes) {attrsets = with attrsets; external // internal;}
      // optionalAttrs (elem "lists" includes) {lists = with lists; external // internal;}
      // optionalAttrs (elem "modules" includes) {modules = with modules; external // internal;}
      // optionalAttrs (elem "options" includes) {options = with options; external // internal;}
      // optionalAttrs (elem "strings" includes) {strings = with strings; external // internal;}
      // optionalAttrs (elem "types" includes) {types = with types; external // internal;}
    ));
  };

  #~@ Curated from nixpkgs.lib
  legacy = import ./nixpkgs.nix {inherit lib;};

  #~@ Namespaced lix.<name>.*
  custom = {
    attrsets = import ./attrsets.nix (mkLix ["debug" "lists" "types"]);
    debug = import ./debug.nix (mkLix ["lists" "types"]);
    lists = import ./lists.nix (mkLix ["debug" "types"]);
    modules = import ./modules.nix (mkLix ["debug" "lists" "types"]);
    options = import ./options.nix (mkLix ["debug" "lists" "types"]);
    strings = import ./strings.nix (mkLix ["debug" "lists" "types"]);
    types = import ./types.nix (mkLix ["debug"]);
  };

  #~@ Flat - lix.*
  aliases = custom.attrsets.internal.merge {
    items = custom;
    getAttrs = name: custom.${name}.external or {};
    what = "libraries: external aliases";
  };
in
  {}
  # // aliases
  // custom
# mapAttrs (_: lib: lib.internal) custom
