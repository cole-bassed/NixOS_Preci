{
  attrsets ? {},
  lists ? {},
  defaults ? {},
  flake ? {},
  names ? {},
  ...
}: let
  exports =
    {
      inputs = {inherit raw classified normalized;};
      inherit types;
    }
    // types;
  types = {
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

  inherit (builtins) attrNames elem filter head isAttrs listToAttrs isString;

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

  defaultOrAllValues =
    attrsets.defaultOrAllValues or (
      set:
        if isAttrs set
        then
          if set ? default
          then [set.default]
          else attrValues set
        else []
    );

  raw =
    filterAttrs
    (input: _: !(elem input ["self" (flake.name or names.src)]))
    inputs;

  classified = {
    nixpkgs = filterAttrs (_: isNixpkgsLike) raw;
    nix-darwin = filterAttrs (_: isNixDarwinLike) raw;
    treefmt = filterAttrs (_: isTreefmtLike) raw;
    colmena = filterAttrs (input: _: input == "deployColmena") raw;
    nixos-anywhere = filterAttrs (input: _: input == "deployNixosAnywhere") raw;

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
          hasFlakeModules value
          && !(isNixpkgsLike value)
        # && input != "nixHM"
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
      (input: _: elem input ["deployColmena" "deployNixosAnywhere"])
      raw;
  };

  normalized = recursiveUpdate classified {
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

  inherit (attrsets) getAttr hasAttr maps orEmpty attrValues;
  inherit (lists) asIf concat unique;

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
                defaultOrAllValues mods
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
                (defaultOrAllValues (getAttr moduleAttr input))
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

  /**
  Return whether an input exposes a `lib` attribute.

  # Type

  ```nix
  hasLibraries :: AttrSet -> Bool
  ```

  # Dependencies

  None
  */
  hasLibraries = input:
    input ? lib;

  /**
  Return whether an input exposes any recognized module namespace.

  # Type

  ```nix
  hasFlakeModules :: AttrSet -> Bool
  ```

  # Dependencies

  None
  */
  hasFlakeModules = input:
    hasCoreModules input || hasHomeModules input;
  hasCoreModules = input:
    input ? nixosModules || input ? darwinModules;
  hasHomeModules = input:
    input ? homeModules || input ? homeManagerModules;

  /**
  Return whether an input exposes overlays.

  # Type

  ```nix
  hasOverlays :: AttrSet -> Bool
  ```

  # Dependencies

  None
  */
  hasOverlays = input:
    input ? overlays;

  /**
  Return whether an input summary should be treated as flake-like.

  # Type

  ```nix
  isFlakeLike :: AttrSet -> Bool
  ```
  */
  isFlakeLike = inputs:
    ((inputs.classified.modules or {}) != {})
    || ((inputs.classified.overlays or {}) != {})
    || ((inputs.normalized.nixpkgs or {}) != {});

  /**
  Return whether an input looks like a nixpkgs-style input.

  # Type

  ```nix
  isNixpkgsLike :: AttrSet -> Bool
  ```

  # Dependencies

  None
  */
  isNixpkgsLike = input:
    input ? legacyPackages
    && input ? lib
    && !(input ? __functor);

  /**
  Return whether an input looks like nix-darwin.

  # Type

  ```nix
  isNixDarwinLike :: AttrSet -> Bool
  ```

  # Dependencies

  None
  */
  isNixDarwinLike = input:
    input ? darwinModules
    && input ? lib
    && !(input ? legacyPackages)
    && !(input ? nixosModules)
    && !(input ? homeModules)
    && !(input ? homeManagerModules);

  /**
  Return whether an input looks like home-manager.

  # Type

  ```nix
  isHomeManagerLike :: AttrSet -> Bool
  ```

  # Dependencies

  None
  */
  isHomeManagerLike = input:
    input ? nixosModules
    && input ? darwinModules
    && input ? legacyPackages
    && input ? lib
    && input ? flakeModules
    && !(input ? homeModules);

  /**
  Return whether an input looks like treefmt-nix.

  # Type

  ```nix
  isTreefmtLike :: AttrSet -> Bool
  ```

  # Dependencies

  - flakes.hasFlakeModules
  - flakes.hasOverlays
  */
  isTreefmtLike = input:
    input ? lib
    && input.lib ? evalModule
    && input ? flakeModule
    && !(input ? legacyPackages)
    && !(hasFlakeModules input)
    && !(hasOverlays input);

  /**
  Return whether an input is nixpkgs-like infrastructure only.

  # Type

  ```nix
  isNixpkgsInfrastructure :: AttrSet -> Bool
  ```

  # Dependencies

  - flakes.isNixpkgsLike
  - flakes.hasFlakeModules
  - flakes.hasOverlays
  */
  isNixpkgsInfrastructure = input:
    isNixpkgsLike input
    && !(hasFlakeModules input)
    && !(hasOverlays input);
in
  exports
