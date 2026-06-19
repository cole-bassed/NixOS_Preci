{
  attrsets,
  lists,
  types,
  defaults,
  flake,
  names,
  ...
}: let
  exports = {
    scoped = {inherit raw classified normalized;};
    global = {
      flakes.inputs = normalized;
      flakeInputs = normalized;
    };
  };

  inputs = flake.inputs or {};
  inherit (lists) elem;
  inherit (attrsets) recursiveAttrs filterAttrs firstOf;
  inherit (types) hasLib hasModules hasOverlays isHomeManagerLike isNixDarwinLike isNixpkgsInfrastructure isNixpkgsLike isTreefmtLike isString;

  raw =
    filterAttrs
    (input: _: !(elem input ["self" (flake.name or names.src)]))
    inputs;

  classified = {
    nixpkgs = filterAttrs (_: isNixpkgsLike) raw;
    nix-darwin = filterAttrs (_: isNixDarwinLike) raw;
    treefmt = filterAttrs (_: isTreefmtLike) raw;

    home-manager =
      filterAttrs
      (
        input: isHomeManagerLike
        # || input == "nixHM"
      )
      raw;

    modules =
      filterAttrs
      (
        input: value:
          hasModules value
          && !(isNixpkgsLike value)
        # && input != "nixHM"
      )
      raw;

    overlays = filterAttrs (_: hasOverlays) raw;

    packages =
      filterAttrs
      (_: value: value ? packages && !(isNixpkgsLike value))
      raw;

    libraries = filterAttrs (_: hasLib) raw;
    infrastructure = filterAttrs (_: isNixpkgsInfrastructure) raw;
  };

  normalized = recursiveAttrs classified {
    inherit raw;
    nixpkgs =
      if flake ? nixpkgs
      then
        if isString (flake.nixpkgs or {})
        then inputs.${flake.nixpkgs}
        else flake.nixpkgs
      else if defaults ? nixpkgs
      then
        if isString (defaults.nixpkgs or {})
        then inputs.${defaults.nixpkgs}
        else defaults.nixpkgs
      else firstOf classified.nixpkgs;

    nix-darwin = firstOf classified.nix-darwin;
    home-manager = firstOf classified.home-manager;
    treefmt = firstOf classified.treefmt;
  };
in
  exports.scoped
