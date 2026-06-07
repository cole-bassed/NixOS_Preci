{
  defaults,
  inputs,
  names,
  paths,
  root,
}: let
  bootstrap = import ./bootstrap.nix;
  inherit
    (bootstrap)
    asAttrsIf
    attrValues
    collectModules
    concatLists
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
        (_: input: hasModules input && !(isNixpkgsLike input))
        raw;
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
      );
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
  in (
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
    )
  );

  modules = let
    collect = type: collectModules type inputs'.classified.modules;
  in {
    mkCore = type:
      if type == "nixos" || type == "darwin"
      then collect type ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      else throw "modules::mkCore:= unknown type '${type}'";

    home = collect "home";
  };

  overlays = let
    all = filterAttrs (_: value: value != {}) (mapAttrs (
        _: input:
          if input ? overlays
          then input.overlays
          else {}
      )
      inputs'.classified.overlays);
  in {
    inherit all;
    default = concatLists (map attrValues (attrValues all));
  };

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
  asAttrsIf (isFlakeLike inputs') {
    flake = {
      inherit modules overlays packages libraries;
      name = names.src;
      path = paths.src;
      inputs = inputs';

      # treefmt = asAttrsIf (inputs'.normalized.treefmt != null) (
      #   inputs'.normalized.treefmt.lib // {inherit root;}
      # );
      # nixpkgs = inputs'.normalized.nixpkgs;
      # darwin = inputs'.normalized.nix-darwin;
      # home-manager = inputs'.normalized.home-manager;
    };
  }
  // libraries
