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
    scoped = {
      inputs = {inherit raw classified normalized;};
      inherit
        collectModules
        preferDefaultModules
        getPackages
        ;
    };
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

  inherit (attrsets) getAttr hasAttr maps orEmpty attrValues;
  inherit (lists) asIf concat unique;

  /**
  Prefer a module set's `default` entry when present.

  If `modules.default` exists, returns a singleton list containing only that
  module. Otherwise returns all attribute values of the module set.

  # Type

  ```nix
  preferDefault :: AttrSet -> List
  ```

  # Dependencies

  None
  */
  preferDefaultModules = modules:
    if modules ? default
    then [modules.default]
    else attrValues modules;

  /**
  Collect modules of a given type from a set of flake inputs.

  Supported types:
  - `nixos`
  - `darwin`
  - `home`

  # Type

  ```nix
  collect :: String -> AttrSet -> List
  ```

  # Dependencies

  - lists.asIf
  - lists.unique
  - modules.preferDefault
  */
  collectModules = type: modules: let
    moduleAttr =
      if type == "nixos"
      then "nixosModules"
      else if type == "darwin"
      then "darwinModules"
      else if type == "home"
      then "homeModules"
      else throw "modules.collect:= unsupported type '${type}'";

    rawCollected =
      if type == "home"
      then
        concat (
          attrValues (
            maps
            (
              _: input: let
                mods =
                  if hasAttr "homeModules" input
                  then input.homeModules
                  else input.homeManagerModules or {};
              in
                preferDefaultModules mods
            )
            modules
          )
        )
      else
        concat (
          attrValues (
            maps
            (
              _: input:
                asIf
                (hasAttr moduleAttr input)
                (preferDefaultModules (getAttr moduleAttr input))
            )
            modules
          )
        );
  in
    unique rawCollected;

  /**
  Normalize package exports from a flake-like input.

  Supports both `legacyPackages` and `packages` layouts and always returns
  an attrset. When both exist, `packages` is merged over `legacyPackages`.

  # Type

  ```nix
  getPackages :: AttrSet -> AttrSet
  ```

  # Dependencies

  - attrsets.orEmpty

  # Arguments

  input
  : The flake-like input to inspect.

  # Examples

  ```nix
  getPackages { packages.x86_64-linux.hello = {}; }
  # => { x86_64-linux.hello = {}; }
  ```
  */
  getPackages = input: let
    value = orEmpty input;
  in
    orEmpty (value.legacyPackages or {})
    // orEmpty (value.packages or {});
in
  exports.scoped
