{
  bootstrap,
  defaults,
  inputs,
  names,
  ...
}: let
  inherit (bootstrap) attrsets lists types;
  inherit (lists) isIn;
  inherit (attrsets) filter firstOf;
  inherit (types) hasLib hasModules hasOverlays isHomeManagerLike isNixDarwinLike isNixpkgsInfrastructure isNixpkgsLike isNotEmpty isTreefmtLike;

  raw =
    filter
    (input: _: !(isIn input ["self" names.src]))
    inputs;

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
in {inherit raw classified normalized merged;}
