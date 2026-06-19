{
  bootstrap,
  attrsets,
  lists,
  excludes,
  defaults,
  ...
}: let
  exports = {
    scoped = {
      inherit
        classified
        normalized
        excluded
        ;
      hasFlake = hasFlakeModules;
      hasHome = hasHomeModules;
      hasCore = hasCoreModules;
      mkFlake = mkModules;
      collectFlake = collectModules;
      merged = classified // normalized;
      default = normalized;
    };
    global = {
      inherit hasFlakeModules;
      mkFlakeModules = mkModules;
      hasFlakeCoreModules = hasCoreModules;
      hasFlakeHomeModules = hasHomeModules;
      collectFlakeModules = collectModules;
    };
  };
  inherit
    (bootstrap)
    inputs
    collectModules
    hasFlakeModules
    hasHomeModules
    hasCoreModules
    ;
  inherit (attrsets) attrNames filterAttrs isAttrs;
  inherit (lists) asListIf elem;

  excluded = excludes.modules or [];

  classified =
    filterAttrs
    (input: _: !(elem input excluded))
    inputs.classified.modules;

  normalized = let
    mk = type: collectModules type classified;
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
