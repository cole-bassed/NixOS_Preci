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
        ;
      hasFlake = hasFlakeModules;
      hasHome = hasHomeModules;
      hasCore = hasCoreModules;
      mkFlake = mkModules;
      collectFlake = collectModules;
      default = normalized;
    };

    global = {
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
  inherit (lists) asListIf elem concatLists;

  registry = flake.registry or {};

  # Registry entries are the processed inputs' records (each has `source`,
  # `scopes`, `modules`, etc.).  We filter to entries that carry at least a
  # `source` field so the `aggregated` sentinel is excluded.
  registryEntries =
    if flake ? modules && flake.modules ? registry
    then filterAttrs (_: entry: isAttrs entry && entry ? source) flake.modules.registry
    else if registry ? inputs
    then filterAttrs (_: entry: isAttrs entry && entry ? source) registry.inputs
    else filterAttrs (_: entry: isAttrs entry && entry ? source) registry;

  hasManualRegistry = registryEntries != {};

  # ── classified ─────────────────────────────────────────────────────────────
  # A set of all inputs that expose at least one module namespace.
  # No policy filtering: scope-based selection happens downstream in
  # assembly.nix via registry.aggregated.modules.select(hostScopes).
  classified = {
    nixos = inputs.classified.modules;
    darwin = inputs.classified.modules;
    home = inputs.classified.modules;
  };

  # ── autoNormalized ──────────────────────────────────────────────────────────
  # Fallback used when there is no manual registry.  Collects all modules of
  # each class from every module-bearing input.
  autoNormalized = {
    nixos = collectModules "nixos" classified.nixos;
    darwin = collectModules "darwin" classified.darwin;
    home = collectModules "home" classified.home;
  };

  # ── normalized ─────────────────────────────────────────────────────────────
  # When a manual registry is present, build module lists directly from the
  # registry entries (which have already been processed by registerModules in
  # flake.nix).  This is the ALL-modules view; per-host filtering is the
  # responsibility of assembly.nix / mkHostScopes.
  normalized =
    if hasManualRegistry
    then {
      nixos = concatLists (
        map (name: registryEntries.${name}.modules.nixos or [])
        (attrNames registryEntries)
      );
      darwin = concatLists (
        map (name: registryEntries.${name}.modules.darwin or [])
        (attrNames registryEntries)
      );
      home = concatLists (
        map (name: registryEntries.${name}.modules.home or [])
        (attrNames registryEntries)
      );
    }
    else autoNormalized;

  merged = classified // normalized;

  # ── mkHM / mkCore ──────────────────────────────────────────────────────────
  # mkCore adds the home-manager NixOS/Darwin module and the nixpkgs allowUnfree
  # config.  These are injected into the fallback path (mkModules) only.
  # The primary path (scopedModsFor in assembly.nix) handles both itself:
  # home-manager comes from the registry via the "core" scope, and the nixpkgs
  # config is injected as an inline module.
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
      ++ asListIf (!hasManualRegistry) (mkHM type)
    );

  # ── mkModules ───────────────────────────────────────────────────────────────
  # Returns ALL modules of a given class plus the synthesised core config.
  # Used as the fallback in assembly.nix scopedModsFor when no registry
  # aggregated data is available.
  mkModules = type:
    if elem type (attrNames normalized)
    then normalized.${type} ++ (mkCore type)
    else throw "modules.mkModules: unknown type '${type}', expected one of [${builtins.concatStringsSep ", " (attrNames normalized)}]";
in
  exports
