{
  attrsets ? {},
  lists ? {},
  defaults ? {},
  flake ? {},
  names ? {},
  types ? {},
  ...
}: let
  exports =
    {
      inputs = {inherit raw classified normalized;};
      types = predicates;
      # modulePolicy removed — the flake.nix registry (inputs' + scopes) is the
      # authoritative policy.  Host-level filtering is done by mkHostScopes +
      # registry.aggregated.modules.select in assembly.nix.
    }
    // predicates;

  predicates = {
    inherit
      collectModules
      getPackages
      hasLibraries
      hasFlakeModules
      hasCoreModules
      hasHomeModules
      hasOverlays
      isFlakeLike
      isHomeManagerLike
      isNixDarwinLike
      isNixpkgsInfrastructure
      isNixpkgsLike
      isTreefmtLike
      ;
  };

  inputs = flake.inputs or {};
  registry = flake.registry or {};
  isRegistryEntry = entry:
    isAttrs entry
    && entry ? source;
  registryEntries =
    registry.inputs or (filterAttrs (_: isRegistryEntry) registry);
  unwrapRegistryEntry = name: entry: let
    source = entry.source or entry.value or null;
    meta = removeAttrs entry ["source" "modules" "overlays" "libraries" "value"];
  in
    if isAttrs source
    then source // meta // {inherit name;}
    else entry;
  registryInputs =
    flake.imports or (mapAttrs unwrapRegistryEntry registryEntries);

  inherit (attrsets) attrNames getAttr hasAttr listToAttrs isAttrs maps mapAttrs orEmpty attrValues;
  inherit (lists) concatLists elem filter head length unique;
  inherit (types) concatStringsSep isString;

  filterAttrs =
    attrsets.filterAttrs or (predicate: set:
      listToAttrs (
        map
        (name: {
          inherit name;
          value = set.${name};
        })
        (
          filter
          (name: predicate name set.${name})
          (attrNames set)
        )
      ));

  recursiveUpdate =
    attrsets.recursiveUpdate or (
      lhs: rhs:
        if isAttrs lhs && isAttrs rhs
        then
          listToAttrs (map
            (name: {
              inherit name;
              value =
                if lhs ? ${name} && rhs ? ${name}
                then recursiveUpdate lhs.${name} rhs.${name}
                else rhs.${name} or lhs.${name};
            })
            (unique (attrNames lhs ++ attrNames rhs)))
        else rhs
    );

  firstOf =
    attrsets.firstOf or (
      set:
        if set == {}
        then null
        else head (attrValues set)
    );

  unwrapRegistryInput = entry:
    if isAttrs entry && entry ? value
    then let
      inherit (entry) value;
      meta = builtins.removeAttrs entry ["value"];
    in
      if isAttrs value
      then value // meta
      else entry
    else entry;

  # ──────────────────────────────────────────────────────────────────────────
  # pickModules
  #
  # Extracts the relevant module value(s) from a source's module namespace.
  # Fine-grained key selection is handled upstream by the flake.nix registry
  # (registerModules), so here we just need sensible defaults:
  #
  #   • Use `default` when present — explicit beats implicit.
  #   • Accept a singleton set without requiring a `default` key.
  #   • Error with a clear message when multiple keys exist and none is `default`,
  #     pointing the author toward the registry as the fix.
  # ──────────────────────────────────────────────────────────────────────────
  pickModules = type: name: set: let
    values = attrValues set;
  in
    if set ? default
    then [set.default]
    else if length values == 1
    then values
    else
      throw ''
        flakes.collectModules: ${name}.${type} exposes multiple module keys with no 'default'.
        Available keys: ${concatStringsSep ", " (attrNames set)}
        Fix: add a 'default' key to the input's module set, or declare explicit
        module keys in the flake.nix inputs' registry entry for '${name}'.
      '';

  raw =
    filterAttrs
    (input: _: !(elem input ["self" (flake.name or names.src)]))
    inputs;

  collectModules = type: inputs: let
    attr =
      if type == "nixos"
      then "nixosModules"
      else if type == "darwin"
      then "darwinModules"
      else if type == "home"
      then "homeModules"
      else throw "flakes.collectModules:= unsupported type '${type}'";

    legacy =
      if type == "home"
      then "homeManagerModules"
      else null;

    get = name: input:
      if hasAttr attr input
      then pickModules type name (getAttr attr input)
      else if legacy != null && hasAttr legacy input
      then pickModules type name (getAttr legacy input)
      else [];
  in
    concatLists (attrValues (maps get inputs));

  flattenRegistryModules = modules:
    concatLists (
      map
      (value:
        if isAttrs value
        then concatLists (attrValues value)
        else value)
      (attrValues modules)
    );
  hasRegistryModules = entry:
    flattenRegistryModules (entry.modules or {}) != [];

  autoClassified = {
    nixpkgs = filterAttrs (_: isNixpkgsLike) raw;
    nix-darwin = filterAttrs (_: isNixDarwinLike) raw;
    treefmt = filterAttrs (_: isTreefmtLike) raw;
    colmena = filterAttrs (input: _: input == "deployColmena") raw;
    nixos-anywhere = filterAttrs (input: _: input == "deployAnywhere") raw;

    home-manager =
      filterAttrs
      (
        _input: isHomeManagerLike
      )
      raw;

    modules =
      filterAttrs
      (
        _input: value:
          hasFlakeModules value
          && !(isNixpkgsLike value)
          && !(isHomeManagerLike value)
          && !(isNixDarwinLike value)
          && !(isTreefmtLike value)
      )
      raw;

    overlays = filterAttrs (_: hasOverlays) raw;

    packages =
      filterAttrs
      (_: value: value ? packages && !(isNixpkgsLike value))
      raw;

    libraries = filterAttrs (_: hasLibraries) raw;
    infrastructure = filterAttrs (_: isNixpkgsInfrastructure) raw;
    deployment =
      filterAttrs
      (input: _: elem input ["deployColmena" "deployAnywhere"])
      raw;
  };

  registryClassified = {
    nixpkgs = filterAttrs (_: isNixpkgsLike) registryInputs;
    nix-darwin = filterAttrs (_: isNixDarwinLike) registryInputs;
    treefmt = filterAttrs (_: isTreefmtLike) registryInputs;
    colmena = filterAttrs (name: _: name == "colmena") registryInputs;
    nixos-anywhere = filterAttrs (name: _: name == "nixos-anywhere") registryInputs;
    home-manager = filterAttrs (_: isHomeManagerLike) registryInputs;
    modules = filterAttrs (name: _: hasRegistryModules (registryEntries.${name} or {})) registryInputs;
    overlays = filterAttrs (name: _: (registryEntries.${name}.overlays or {}) != {}) registryInputs;
    packages = filterAttrs (_: value: getPackages value != {}) registryInputs;
    libraries = filterAttrs (_: hasLibraries) registryInputs;
    infrastructure = filterAttrs (name: _: elem "infrastructure" (registryEntries.${name}.profiles or [])) registryInputs;
    deployment = filterAttrs (name: _: elem "deployment" (registryEntries.${name}.profiles or [])) registryInputs;
  };

  classified =
    if registryInputs != {}
    then registryClassified
    else autoClassified;

  autoNormalized = recursiveUpdate classified {
    inherit raw;
    nixpkgs =
      if flake ? nixpkgs
      then
        if isString (flake.nixpkgs or {})
        then let name = flake.nixpkgs; in inputs.${name} // {inherit name;}
        else flake.nixpkgs
      else if defaults ? nixpkgs
      then
        if isString defaults.nixpkgs
        then let name = defaults.nixpkgs; in inputs.${name} // {inherit name;}
        else defaults.nixpkgs
      else firstOf classified.nixpkgs;

    nix-darwin = firstOf classified.nix-darwin;
    home-manager = firstOf classified.home-manager;
    treefmt = firstOf classified.treefmt;
    colmena = firstOf classified.colmena;
    nixos-anywhere = firstOf classified."nixos-anywhere";
    deployment = {
      colmena = firstOf classified.colmena;
      nixos-anywhere = firstOf classified."nixos-anywhere";
    };
  };

  normalized = autoNormalized // (mapAttrs (_: unwrapRegistryInput) registryInputs);

  getPackages = input: let
    value = orEmpty input;
  in
    orEmpty (value.legacyPackages or {})
    // orEmpty (value.packages or {});

  hasLibraries = input:
    input ? lib;

  hasFlakeModules = input:
    hasCoreModules input || hasHomeModules input;
  hasCoreModules = input:
    input ? nixosModules || input ? darwinModules;
  hasHomeModules = input:
    input ? homeModules || input ? homeManagerModules;

  hasOverlays = input:
    input ? overlays;

  isFlakeLike = inputs:
    ((inputs.classified.modules or {}) != {})
    || ((inputs.classified.overlays or {}) != {})
    || ((inputs.normalized.nixpkgs or {}) != {});

  isNixpkgsLike = input:
    input ? legacyPackages
    && input ? lib
    && !(input ? __functor);

  isNixDarwinLike = input:
    input ? darwinModules
    && input ? lib
    && !(input ? legacyPackages)
    && !(input ? nixosModules)
    && !(input ? homeModules)
    && !(input ? homeManagerModules);

  isHomeManagerLike = input:
    input ? nixosModules
    && input ? darwinModules
    && input ? legacyPackages
    && input ? lib
    && input ? flakeModules
    && !(input ? homeModules);

  isTreefmtLike = input:
    input ? lib
    && input.lib ? evalModule
    && input ? flakeModule
    && !(input ? legacyPackages)
    && !(hasFlakeModules input)
    && !(hasOverlays input);

  isNixpkgsInfrastructure = input:
    isNixpkgsLike input
    && !(hasFlakeModules input)
    && !(hasOverlays input);
in
  exports
