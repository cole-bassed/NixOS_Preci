{
  bootstrap,
  attrsets,
  flake,
  lists,
  defaults,
  ...
}: let
  exports = {
    scoped = {
      inherit
        classified
        normalized
        merged
        excluded
        ;
      hasFlake = hasFlakeModules;
      hasHome = hasHomeModules;
      hasCore = hasCoreModules;
      mkFlake = mkModules;
      collectFlake = collectModules;
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

  inherit (attrsets) attrNames attrValues filterAttrs isAttrs;
  inherit (lists) asListIf elem;
  registry = flake.registry or {};
  registryModules =
    if registry ? modules
    then registry.modules
    else flake.modules.registry or {};
  hasManualRegistry = registryModules != {};

  excluded = let
    value = bootstrap.modulePolicy.excludes or [];
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

  included = bootstrap.modulePolicy.includes or {};

  isIncluded = type: name: let
    scope = included.${type} or null;
  in
    !(elem name (excluded.${type} or []))
    && (
      scope
      == null
      || elem name scope
    );

  autoClassified = let
    classify = type:
      filterAttrs
      (name: _: isIncluded type name)
      inputs.classified.modules;
  in {
    nixos = classify "nixos";
    darwin = classify "darwin";
    home = classify "home";
  };

  classified = autoClassified;

  autoNormalized = {
    nixos = collectModules "nixos" classified.nixos;
    darwin = collectModules "darwin" classified.darwin;
    home = collectModules "home" classified.home;
  };

  normalized =
    if hasManualRegistry
    then {
      nixos = map (entry: entry.value) (attrValues (filterAttrs (_: entry: (entry.class or null) == "nixos") registryModules));
      darwin = map (entry: entry.value) (attrValues (filterAttrs (_: entry: (entry.class or null) == "darwin") registryModules));
      home = map (entry: entry.value) (attrValues (filterAttrs (_: entry: (entry.class or null) == "home") registryModules));
    }
    else autoNormalized;

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
    ((elem type ["nixos" "darwin"]) && !hasManualRegistry)
    (
      [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      ++ (mkHM type)
    );

  mkModules = type:
    if elem type (attrNames normalized)
    then normalized.${type} ++ (mkCore type)
    else throw "external.modules.mkMods: unknown type '${type}'";
in
  exports
