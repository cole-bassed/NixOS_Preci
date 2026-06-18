{
  bootstrap,
  defaults,
  inputs,
  ...
}: let
  inherit (bootstrap) attrsets config lists;
  inherit (attrsets) filter isAttrs namesOf;
  inherit (config) collect;
  inherit (lists) asListIf isIn;

  excludes = defaults.excludes.modules or [];

  classified =
    filter
    (input: _: !(isIn input excludes))
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
    (isIn type ["nixos" "darwin"])
    (
      [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      ++ (mkHM type)
    );

  mkMods = type:
    if (isIn type (namesOf merged))
    then merged.${type} ++ (mkCore type)
    else throw "external.modules.mkMods: unknown type '${type}'";
in {inherit classified normalized excludes merged mkMods;}
