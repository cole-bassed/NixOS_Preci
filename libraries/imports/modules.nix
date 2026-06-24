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

  excluded = let
    value = excludes.modules or [];
  in
    if isAttrs value
    then {
      nixos = value.nixos or [];
      darwin = value.darwin or [];
      home = value.home or [];
    }
    else {
      nixos = value;
      darwin = value;
      home = value;
    };

  classified = type:
    filterAttrs
    (name: _: !(elem name (excluded.${type} or [])))
    inputs.classified.modules;

  normalized = {
    nixos = collectModules "nixos" (classified "nixos");
    darwin = collectModules "darwin" (classified "darwin");
    home = collectModules "home" (classified "home");
  };

  classifiedByType = {
    nixos = classified "nixos";
    darwin = classified "darwin";
    home = classified "home";
  };

  merged = classifiedByType // normalized;

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
