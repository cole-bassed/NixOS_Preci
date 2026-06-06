{
  inputs ? {},
  self ? {},
  defaults ? {allowUnfree = true;},
}: let
  bootstrap = import ./bootstrap.nix;
  inherit
    (bootstrap)
    asAttrsIf
    asListIf
    attrValues
    collectModules
    concatLists
    filterAttrs
    hasLib
    hasModules
    hasOverlays
    isNixpkgsInfrastructure
    isNixpkgsLike
    isNotEmpty
    mapAttrs
    orEmptyAttr
    preferDefaultModules
    ;

  inputs' = let
    attrs = orEmptyAttr inputs;

    classified = {
      nixpkgs = filterAttrs (_: isNixpkgsLike) attrs;
      modules = filterAttrs (_: hasModules) attrs;
      overlays = filterAttrs (_: hasOverlays) attrs;
      libraries = filterAttrs (_: hasLib) attrs;
      infrastructure = filterAttrs (_: isNixpkgsInfrastructure) attrs;
    };
    normalized = {
      nixpkgs = filterAttrs (_: isNixpkgsLike) attrs;
      darwin = filterAttrs (_: input: input ? darwinModules) attrs;
      home-manager = filterAttrs (_: input: input ? homeManagerModules || input ? homeModules) attrs;
      treefmt = filterAttrs (_: input: input ? formatter && input ? lib.evalModule) attrs;
    };
  in {inherit classified normalized;};

  libraries = let
    classified = mapAttrs (_: input: input.lib) inputs'.classified.libraries;
    normalized = filterAttrs (_: value: value != null) inputs'.normalized;
    nixpkgs = import ./nixpkgs.nix inputs'.classified.nixpkgs;
  in
    bootstrap
    // nixpkgs
    // classified
    // normalized
    // {inherit nixpkgs bootstrap;}
    // (
      asAttrsIf
      (normalized ? treefmt)
      {treefmt = normalized.treefmt // {inherit self;};}
    );

  modules = let
    collect = type: collectModules type inputs'.classified.modules;
  in {
    mkCore = type:
      if type == "nixos" || type == "darwin"
      then
        (collect type)
        ++ [{nixpkgs.config = {inherit (defaults) allowUnfree;};}]
      else throw "modules::mkCore:= unknown type '${type}'";
    home = collect "home";
  };

  overlays = let
    available =
      filterAttrs
      (_: value: value != [])
      (
        mapAttrs
        (
          _: input:
            asListIf
            (input ? overlays)
            (preferDefaultModules input.overlays)
        )
        inputs'.classified.overlays
      );
  in {
    inherit available;
    evaluated = concatLists (attrValues available);
  };

  packages = inputs'.normalized.nixpkgs.legacyPackages or {};
in {
  inherit libraries modules overlays packages;
  inputs = inputs';
}
