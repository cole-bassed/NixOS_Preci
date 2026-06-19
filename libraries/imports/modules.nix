{
  attrsets,
  lists,
  excludes,
  defaults,
  inputs,
  modules,
  ...
}: let
  exports = {
    scoped = {
      inherit classified normalized mkModules excluded;
      mkMods = mkModules;
    };
    global = {
      flakes = {
        modules = normalized;
        inherit mkModules;
      };
    };
  };
  inherit (modules) collect;
  inherit (attrsets) attrNames filterAttrs isAttrs;
  inherit (lists) asListIf elem;

  excluded = excludes.modules or [];

  classified =
    filterAttrs
    (input: _: !(elem input excluded))
    inputs.classified.modules;

  normalized = let
    mk = type: collect type classified;
  in {
    nixos = mk "nixos";
    darwin = mk "darwin";
    home = mk "home";
  };

  merged = classified // normalized;

  mkHM = type: let
    key =
      if type == "nixos"
      then "nixosModules"
      else if type == "darwin"
      then "darwinModules"
      else null;
    input = inputs.normalized.home-manager;
  in
    asListIf
    (
      (key != null)
      && (isAttrs input)
      && input ? ${key}.home-manager
    )
    input.${key}.home-manager;

  mkCore = type:
    asListIf
    (elem type ["nixos" "darwin"])
    (
      [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      ++ (mkHM type)
    );

  mkModules = type:
    if (elem type (attrNames merged))
    then merged.${type} ++ (mkCore type)
    else throw "external.modules.mkMods: unknown type '${type}'";
in
  exports
