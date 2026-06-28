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
  firstNonEmpty =
    lists.firstOf or (
      sets:
        if sets == []
        then []
        else let
          nonEmpty = builtins.filter (set: set != []) sets;
        in
          if nonEmpty == []
          then []
          else builtins.head nonEmpty
    );
  registry = flake.registry or {};
  registryEntries =
    if flake ? modules && flake.modules ? registry
    then filterAttrs (_: entry: isAttrs entry && entry ? source) flake.modules.registry
    else if registry ? inputs
    then filterAttrs (_: entry: isAttrs entry && entry ? source) registry.inputs
    else filterAttrs (_: entry: isAttrs entry && entry ? source) registry;
  hasManualRegistry = registryEntries != {};

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
      || scope == []
      || elem name scope
    );

  classified = {
    nixos = filterAttrs (name: _: isIncluded "nixos" name) inputs.classified.modules;
    darwin = filterAttrs (name: _: isIncluded "darwin" name) inputs.classified.modules;
    home = filterAttrs (name: _: isIncluded "home" name) inputs.classified.modules;
  };

  autoNormalized = {
    nixos = collectModules "nixos" classified.nixos;
    darwin = collectModules "darwin" classified.darwin;
    home = collectModules "home" classified.home;
  };

  normalized =
    if hasManualRegistry
    then {
      nixos = builtins.concatLists (
        map
        (name:
          if isIncluded "nixos" name
          then firstNonEmpty (attrValues (registryEntries.${name}.modules.nixos or {}))
          else [])
        (attrNames registryEntries)
      );
      darwin = builtins.concatLists (
        map
        (name:
          if isIncluded "darwin" name
          then firstNonEmpty (attrValues (registryEntries.${name}.modules.darwin or {}))
          else [])
        (attrNames registryEntries)
      );
      home = builtins.concatLists (
        map
        (name:
          if isIncluded "home" name
          then firstNonEmpty (attrValues (registryEntries.${name}.modules.home or {}))
          else [])
        (attrNames registryEntries)
      );
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
    (elem type ["nixos" "darwin"])
    (
      [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      ++ (
        if hasManualRegistry
        then []
        else mkHM type
      )
    );

  mkModules = type:
    if elem type (attrNames normalized)
    then normalized.${type} ++ (mkCore type)
    else throw "external.modules.mkMods: unknown type '${type}'";
in
  exports
