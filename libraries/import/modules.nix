{
  attrsets,
  lists,
  defaults,
  inputs,
  ...
}: let
  inherit (attrsets) attrNames attrValues asAttrsIf filterAttrs hasAttr getAttr isAttrs mapAttrs;
  inherit (lists) asListIf concatLists elem unique;

  excludes = defaults.excludes.modules or [];

  /**
  Prefer a module set's `default` entry when present.

  If `modules.default` exists, returns a singleton list containing only that
  module. Otherwise returns all attribute values of the module set.

  # Type

  ```nix
  preferDefault :: AttrSet -> List
  ```

  # Dependencies

  None
  */
  preferDefault = modules:
    if modules ? default
    then [modules.default]
    else attrValues modules;

  /**
  Collect modules of a given type from a set of flake inputs.

  Supported types:
  - `nixos`
  - `darwin`
  - `home`

  # Type

  ```nix
  collect :: String -> AttrSet -> List
  ```

  # Dependencies

  - lists.asIf
  - lists.unique
  - modules.preferDefault
  */
  collect = type: modules: let
    moduleAttr =
      if type == "nixos"
      then "nixosModules"
      else if type == "darwin"
      then "darwinModules"
      else if type == "home"
      then "homeModules"
      else throw "modules.collect:= unsupported type '${type}'";

    rawCollected =
      if type == "home"
      then
        concatLists (
          attrValues (
            mapAttrs
            (
              _: input: let
                mods =
                  if hasAttr "homeModules" input
                  then input.homeModules
                  else input.homeManagerModules or {};
              in
                preferDefault mods
            )
            modules
          )
        )
      else
        concatLists (
          attrValues (
            mapAttrs
            (
              _: input:
                asAttrsIf
                (hasAttr moduleAttr input)
                (preferDefault (getAttr moduleAttr input))
            )
            modules
          )
        );
  in
    unique rawCollected;

  classified =
    filterAttrs
    (input: _: !(elem input excludes))
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

  mkMods = type:
    if (elem type (attrNames merged))
    then merged.${type} ++ (mkCore type)
    else throw "external.modules.mkMods: unknown type '${type}'";
in {inherit classified normalized excludes merged mkMods;}
