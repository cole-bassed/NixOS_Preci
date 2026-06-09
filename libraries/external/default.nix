{
  bootstrap ? import ../base,
  flake ? {},
}: let
  inherit (bootstrap) attrsets config lists types;
  inherit (config) collect preferDefault getPackages;
  inherit (lists) asListIf concat isIn;
  inherit (attrsets) asIf filter firstOf isAttrs maps orEmpty update valuesOf;
  inherit (types) hasLib hasModules hasOverlays isFlakeLike isHomeManagerLike isNixDarwinLike isNixpkgsInfrastructure isNixpkgsLike isNotEmpty isTreefmtLike;

  defaults = update {allowUnfree = true;} (flake.defaults or {});
  name = flake.name or "dots";
  path = flake.path or ../../.;

  inputs = let
    raw =
      filter
      (input: _: !(isIn input ["self" name]))
      (flake.inputs or {});

    classified = {
      nixpkgs = filter (_: isNixpkgsLike) raw;
      nix-darwin = filter (_: isNixDarwinLike) raw;
      treefmt = filter (_: isTreefmtLike) raw;

      home-manager =
        filter
        (
          input: value:
            isHomeManagerLike value
          # || input == "nixHM"
        )
        raw;

      modules =
        filter
        (
          input: value:
            hasModules value
            && !(isNixpkgsLike value)
          # && input != "nixHM"
        )
        raw;

      overlays = filter (_: hasOverlays) raw;

      packages =
        filter
        (_: value: value ? packages && !(isNixpkgsLike value))
        raw;

      libraries = filter (_: hasLib) raw;
      infrastructure = filter (_: isNixpkgsInfrastructure) raw;
    };

    normalized = {
      nixpkgs =
        if isNotEmpty (defaults.nixpkgs or {})
        then defaults.nixpkgs
        else firstOf classified.nixpkgs;

      nix-darwin = firstOf classified.nix-darwin;
      home-manager = firstOf classified.home-manager;
      treefmt = firstOf classified.treefmt;
    };

    merged = classified // normalized;
  in {inherit raw classified normalized merged;};

  libraries = let
    classified = (
      maps
      (_: input: input.lib)
      inputs.classified.libraries
    );

    treefmt = orEmpty inputs.normalized.treefmt;

    normalized =
      (
        maps
        (_: input: input.lib)
        (
          filter
          (_: value: value != null && value ? lib)
          inputs.normalized
        )
      )
      // {nixpkgs = import ./nixpkgs.nix inputs.normalized.nixpkgs;}
      // asIf (treefmt?lib) {treefmt = treefmt.lib // {inherit path;};};

    merged =
      normalized.nixpkgs
      // classified
      // normalized;
  in {inherit classified normalized merged;};

  modules = let
    excludes = defaults.excludes.modules or [];

    raw =
      filter
      (input: _: !(isIn input excludes))
      inputs.classified.modules;

    classified = let
      mk = type: collect type raw;
    in {
      nixos = mk "nixos";
      darwin = mk "darwin";
      home = mk "home";
    };

    normalized = {
      home-manager = type: let
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
    };

    merged = classified // normalized;

    mkCore = type:
      if type == "nixos" || type == "darwin"
      then
        classified.${type}
        ++ normalized.home-manager type
        ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      else throw "external.modules.mkCore: unknown type '${type}'";
  in {inherit raw classified normalized excludes merged mkCore;};

  overlays = let
    excludes = defaults.excludes.overlays or [];

    raw =
      filter
      (input: _: !(isIn input excludes))
      inputs.classified.overlays;

    classified =
      filter
      (_: value: value != {})
      (maps (_: input: input.overlays or {}) raw);

    normalized = {};
  in {
    inherit raw classified normalized excludes;

    merged =
      concat
      (map preferDefault (valuesOf (classified // normalized)));
  };

  packages = let
    raw = inputs.classified.packages;

    classified =
      maps
      (_: getPackages)
      raw;

    normalized =
      asIf (inputs.normalized.nixpkgs != null) {
        nixpkgs = getPackages inputs.normalized.nixpkgs;
      }
      // asIf (inputs.normalized.home-manager != null) {
        home-manager = getPackages inputs.normalized.home-manager;
      };
  in {
    inherit raw classified normalized;

    merged = classified // normalized;
    default = orEmpty normalized.nixpkgs;
  };

  exports = {
    inherit
      defaults
      inputs
      libraries
      modules
      name
      overlays
      packages
      path
      ;
  };
in
  libraries.merged
  // {${name} = exports;}
  // asIf (isFlakeLike inputs) {flake = exports;}
