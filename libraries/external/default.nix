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
    getPackages
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
    preferDefaultModules
    orEmptyAttrs
    pickFirst
    ;

  inputs' = let
    raw =
      filterAttrs
      (input: _: !(elem input ["self" names.src names.top]))
      (orEmptyAttrs inputs);

    classified = {
      nixpkgs = filterAttrs (_: isNixpkgsLike) raw;
      nix-darwin = filterAttrs (_: isNixDarwinLike) raw;
      treefmt = filterAttrs (_: isTreefmtLike) raw;

      home-manager =
        filterAttrs
        (input: value: isHomeManagerLike value || input == "nixHM")
        raw;

      modules =
        filterAttrs
        (input: value:
          hasModules value
          && !(isNixpkgsLike value)
          && input != "nixHM")
        raw;

      overlays = filterAttrs (_: hasOverlays) raw;

      packages =
        filterAttrs
        (_: value: value ? packages && !(isNixpkgsLike value))
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
      treefmt = pickFirst classified.treefmt;
    };
  in {
    inherit raw classified normalized;
  };

  nixpkgs =
    if inputs'.normalized.nixpkgs != null
    then import ./nixpkgs.nix inputs'.normalized.nixpkgs
    else {};

  libraries = {
    raw = bootstrap // nixpkgs // {inherit bootstrap nixpkgs;};

    classified =
      mapAttrs
      (_: input: input.lib)
      inputs'.classified.libraries;

    normalized =
      mapAttrs
      (_: input: input.lib)
      (filterAttrs (_: value: value != null && value ? lib) inputs'.normalized);

    merged = with libraries;
      raw
      // classified
      // normalized
      // asAttrsIf (inputs'.normalized.treefmt != null) {
        treefmt =
          inputs'.normalized.treefmt.lib
          // {
            inherit root;
            flake = inputs'.normalized.treefmt;
          };
      };
  };

  modules = let
    excludes = defaults.excludes.modules or [];

    raw =
      filterAttrs
      (input: _: !(elem input excludes))
      inputs'.classified.modules;

    hmModuleKey = type:
      if type == "nixos"
      then "nixosModules"
      else if type == "darwin"
      then "darwinModules"
      else null;

    collect = type: collectModules type raw;

    classified = {
      nixos = collect "nixos";
      darwin = collect "darwin";
      home = collect "home";
    };

    normalized = {
      home-manager = type: let
        key = hmModuleKey type;
        input = inputs'.normalized.home-manager;
      in
        asListIf
        (key != null && input != null && input ? ${key}.home-manager)
        input.${key}.home-manager;
    };
    mkCore = type:
      if type == "nixos" || type == "darwin"
      then
        classified.${type}
        ++ normalized.home-manager type
        ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      else throw "external.modules.mkCore: unknown type '${type}'";
  in {
    inherit raw classified normalized excludes;

    home = classified.home;
    nixos = mkCore "nixos";
    darwin = mkCore "darwin";
  };

  overlays = let
    excludes = defaults.excludes.overlays or [];

    raw =
      filterAttrs
      (input: _: !(elem input excludes))
      inputs'.classified.overlays;

    classified =
      filterAttrs
      (_: value: value != {})
      (mapAttrs (_: input: input.overlays or {}) raw);

    normalized = {};
  in {
    inherit raw classified normalized excludes;

    all = classified // normalized;

    default =
      concatLists
      (map preferDefaultModules (attrValues classified));
  };

  packages = let
    raw = inputs'.classified.packages;

    classified =
      mapAttrs
      (_: getPackages)
      raw;

    normalized =
      asAttrsIf (inputs'.normalized.nixpkgs != null) {
        nixpkgs = getPackages inputs'.normalized.nixpkgs;
      }
      // asAttrsIf (inputs'.normalized.home-manager != null) {
        home-manager = getPackages inputs'.normalized.home-manager;
      };
  in {
    inherit raw classified normalized;

    all = classified // normalized;
    default = orEmptyAttrs normalized.nixpkgs;
  };

  flake = {
    inherit libraries modules overlays packages;

    name = names.src;
    path = paths.src;
    inputs = inputs';

    inherit
      (inputs'.normalized)
      treefmt
      nixpkgs
      nix-darwin
      home-manager
      ;
  };
in
  libraries.merged
  // asAttrsIf (isFlakeLike inputs') {
    inherit flake;
  }
