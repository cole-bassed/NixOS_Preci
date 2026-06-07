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
      home-manager = filterAttrs (name: input: isHomeManagerLike input || name == "nixHM") raw;

      modules =
        filterAttrs
        (
          name: input:
            hasModules input
            && !(isNixpkgsLike input)
            && name != "self"
            && name != "nixHM" # Safeguard structural lookup exclusion
            && name != names.src
            && name != names.top
        )
        raw;

      # home-manager = filterAttrs (_: isHomeManagerLike) raw;

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

  modules = let
    excludes = defaults.excludes.modules or [];

    filteredModules =
      filterAttrs
      (name: _: !(elem name excludes))
      inputs'.classified.modules;

    collect = type: collectModules type filteredModules;

    hmModuleKey = type:
      if type == "nixos"
      then "nixosModules"
      else if type == "darwin"
      then "darwinModules"
      else null;

    # ── GENERIC LIST DEDUPLICATOR ──────────────────────────────────────────
    # Uses standard recursive filtering if lib isn't directly inherited here
    dedup = list:
      if list == []
      then []
      else [(builtins.head list)] ++ dedup (builtins.filter (x: x != builtins.head list) (builtins.tail list));
  in {
    inherit excludes;

    mkCore = type: let
      hmKey = hmModuleKey type;
      hmInput = inputs'.normalized.home-manager;

      # 1. Build the raw combined list containing auto-discovered + explicit items
      rawModulesList =
        if type == "nixos" || type == "darwin"
        then
          collect type
          ++ asListIf
          (hmKey != null && hmInput != null && hmInput ? ${hmKey}.home-manager)
          hmInput.${hmKey}.home-manager
          ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
        else throw "modules::mkCore:= unknown type '${type}'";
    in
      # 2. Force the final list to be strictly unique before returning it
      dedup rawModulesList;

    home = dedup (collect "home");
  };

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
