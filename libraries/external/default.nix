{
  bootstrap,
  defaults,
  inputs,
  names,
  paths,
  root,
}: let
  inherit
    (bootstrap)
    asAttrsIf
    asListIf
    attrValues
    collectModules
    concatLists
    elem
    filterAttrs
    hasLib
    hasModules
    hasOverlays
    isFlakeLike
    isHomeManagerLike
    isNixDarwinLike
    isNixpkgsInfrastructure
    isNixpkgsLike
    isNotEmpty
    isTreefmtLike
    mapAttrs
    orEmptyAttrs
    pickFirst
    ;

  inputs' = let
    raw = filterAttrs (name: _: name != "self") (orEmptyAttrs inputs);

    classified = {
      nixpkgs = filterAttrs (_: isNixpkgsLike) raw;
      nix-darwin = filterAttrs (_: isNixDarwinLike) raw;
      home-manager = filterAttrs (_: isHomeManagerLike) raw;
      modules =
        filterAttrs
        (
          name: input:
            hasModules input
            && !(isNixpkgsLike input)
            && name != "self"
            && name != names.src
            && name != names.top
        )
        raw;

      # modules =
      #   filterAttrs
      #   (_: input: hasModules input && !(isNixpkgsLike input))
      #   raw;

      overlays = filterAttrs (_: hasOverlays) raw;
      packages =
        filterAttrs
        (_: input: input ? packages && !(isNixpkgsLike input))
        raw;
      libraries = filterAttrs (_: hasLib) raw;
      infrastructure = filterAttrs (_: isNixpkgsInfrastructure) raw;
    };

    normalized = {
      nixpkgs =
        if defaults ? nixpkgs && isNotEmpty defaults.nixpkgs
        then defaults.nixpkgs
        else pickFirst classified.nixpkgs;
      nix-darwin = pickFirst classified.nix-darwin;
      home-manager = pickFirst classified.home-manager;
      treefmt = pickFirst (
        filterAttrs (_: isTreefmtLike) raw
      ); # TODO: This is where we should inject root into the lib
    };
  in {inherit raw classified normalized;};

  libraries = let
    classified = mapAttrs (_: input: input.lib) inputs'.classified.libraries;
    normalized = mapAttrs (_: input: input.lib) (
      filterAttrs (_: v: v != null) inputs'.normalized
    );
    nixpkgs =
      if inputs'.normalized.nixpkgs != null
      then import ./nixpkgs.nix inputs'.normalized.nixpkgs
      else {};
  in
    bootstrap
    // nixpkgs
    // classified
    // normalized
    // {inherit bootstrap nixpkgs;}
    // asAttrsIf (isFlakeLike inputs') {
      flakes = {
        inputs = inputs';
        inherit modules overlays packages;
        treefmt = inputs'.normalized.treefmt;
        nixpkgs = inputs'.normalized.nixpkgs;
        darwin = inputs'.normalized.nix-darwin;
        home-manager = inputs'.normalized.home-manager;
      };
    }
    // (
      asAttrsIf (inputs'.normalized.treefmt != null) {
        treefmt =
          inputs'.normalized.treefmt.lib
          // {
            inherit root;
            flake = inputs'.normalized.treefmt;
          };
      }
    );

  # modules = let
  #   collect = type: collectModules type inputs'.classified.modules;

  #   # Map our system types to home-manager's respective internal module keys
  #   hmModuleKey = type:
  #     if type == "nixos"
  #     then "nixosModules"
  #     else if type == "darwin"
  #     then "darwinModules"
  #     else null;
  # in {
  #   mkCore = type: let
  #     hmKey = hmModuleKey type;
  #     hmInput = inputs'.normalized.home-manager;
  #   in
  #     if type == "nixos" || type == "darwin"
  #     then
  #       collect type
  #       ++ asListIf
  #       (hmKey != null && hmInput != null && hmInput ? ${hmKey}.home-manager)
  #       hmInput.${hmKey}.home-manager
  #       ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
  #     else throw "modules::mkCore:= unknown type '${type}'";

  #   home = collect "home";
  # };

  # modules = let
  #   # Safe lookup for your configurable external tester excludes
  #   excludes = defaults.excludes.modules or [];

  #   # Filter your auto-discovered inputs before mkCore processes them
  #   filteredModules =
  #     filterAttrs
  #     (name: _: !(elem name excludes))
  #     inputs'.classified.modules;

  #   collect = type: collectModules type filteredModules;

  #   # Dynamically compute home-manager's internal target module keys
  #   hmModuleKey = type:
  #     if type == "nixos"
  #     then "nixosModules"
  #     else if type == "darwin"
  #     then "darwinModules"
  #     else null;
  # in {
  #   inherit excludes;

  #   mkCore = type: let
  #     hmKey = hmModuleKey type;
  #     hmInput = inputs'.normalized.home-manager;
  #   in
  #     if type == "nixos" || type == "darwin"
  #     then
  #       collect type
  #       # ── RE-INJECT HOME-MANAGER NATIVE LAYER NATIVELY ─────────────────────
  #       ++ asListIf
  #       (hmKey != null && hmInput != null && hmInput ? ${hmKey}.home-manager)
  #       hmInput.${hmKey}.home-manager
  #       # ─────────────────────────────────────────────────────────────────────
  #       ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
  #     else throw "modules::mkCore:= unknown type '${type}'";

  #   home = collect "home";
  # };

  modules = let
    # Clear out lists safely from defaults
    excludes = defaults.excludes.modules or [];

    # ── STEP 1: MODULES EXCLUDED FROM THE SYSTEM LAYER ONLY ──────────────────
    # Stop shellCaelestia from feeding its system files into mkCore "nixos"
    systemFilteredModules =
      filterAttrs
      (name: _: !(elem name excludes) && name != "shellCaelestia")
      inputs'.classified.modules;

    # ── STEP 2: MODULES AVAILABLE TO THE USER HOME LAYER ─────────────────────
    # Leave shellCaelestia untouched here so its homeModules are fully collected!
    homeFilteredModules =
      filterAttrs
      (name: _: !(elem name excludes))
      inputs'.classified.modules;

    collectSystem = type: collectModules type systemFilteredModules;
    collectHome = type: collectModules type homeFilteredModules;

    hmModuleKey = type:
      if type == "nixos"
      then "nixosModules"
      else if type == "darwin"
      then "darwinModules"
      else null;
  in {
    inherit excludes;

    mkCore = type: let
      hmKey = hmModuleKey type;
      hmInput = inputs'.normalized.home-manager;
    in
      if type == "nixos" || type == "darwin"
      then
        collectSystem type # Pulls vendor system modules without caelestia's common.nix
        ++ asListIf
        (hmKey != null && hmInput != null && hmInput ? ${hmKey}.home-manager)
        hmInput.${hmKey}.home-manager
        ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      else throw "modules::mkCore:= unknown type '${type}'";

    home = collectHome "home"; # Grabs caelestia's homeModules perfectly!
  };

  overlays = let
    excludes = defaults.excludes.overlays or [];

    filteredOverlayInputs =
      filterAttrs
      (name: _: !(elem name excludes))
      inputs'.classified.overlays;

    all = filterAttrs (_: value: value != {}) (mapAttrs (
        _: input:
          input.overlays or {}
      )
      filteredOverlayInputs);
  in {
    inherit all excludes;
    default = concatLists (map attrValues (attrValues all));
  };

  # overlays = let
  #   all = filterAttrs (_: value: value != {}) (mapAttrs (
  #       _: input:
  #         input.overlays or {}
  #     )
  #     inputs'.classified.overlays);
  # in {
  #   inherit all;
  #   default = concatLists (map attrValues (attrValues all));
  # };

  packages = let
    classified = mapAttrs (_: input: input.legacyPackages or {}) inputs'.classified.nixpkgs;
    normalized = {
      nixpkgs = inputs'.normalized.nixpkgs.legacyPackages or {};
      home-manager = inputs'.normalized.home-manager.legacyPackages or {};
    };
    all = classified // normalized;
    default = normalized.nixpkgs;
  in {inherit default all classified normalized;};
in
  libraries
  // (
    asAttrsIf (isFlakeLike inputs') {
      flake = {
        inherit modules overlays packages libraries;
        name = names.src;
        path = paths.src;
        inputs = inputs';
      };
    }
  )
