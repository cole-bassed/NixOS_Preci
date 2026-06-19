{types, ...}: let
  exports = {
    scoped = {
      inherit
        hasLib
        hasModules
        hasOverlays
        isFlakeLike
        isHomeManagerLike
        isNixDarwinLike
        isNixpkgsInfrastructure
        isNixpkgsLike
        isTreefmtLike
        ;
    };

    global = {
      inherit
        hasLib
        hasModules
        hasOverlays
        isFlakeLike
        isHomeManagerLike
        isNixDarwinLike
        isNixpkgsInfrastructure
        isNixpkgsLike
        isTreefmtLike
        ;
    };
  };

  inherit (types) isNotEmpty;

  /**
  Return whether an input exposes a `lib` attribute.

  # Type

  ```nix
  hasLib :: AttrSet -> Bool
  ```

  # Dependencies

  None
  */
  hasLib = input:
    input ? lib;

  /**
  Return whether an input exposes any recognized module namespace.

  # Type

  ```nix
  hasModules :: AttrSet -> Bool
  ```

  # Dependencies

  None
  */
  hasModules = input:
    input ? nixosModules
    || input ? darwinModules
    || input ? homeModules
    || input ? homeManagerModules;

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

  # Dependencies

  - types.isNotEmpty
  */
  isFlakeLike = inputs:
    isNotEmpty (inputs.classified.modules or {})
    || isNotEmpty (inputs.classified.overlays or {})
    || isNotEmpty (inputs.normalized.nixpkgs or {});

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

  - flakes.hasModules
  - flakes.hasOverlays
  */
  isTreefmtLike = input:
    input ? lib
    && input.lib ? evalModule
    && input ? flakeModule
    && !(input ? legacyPackages)
    && !(hasModules input)
    && !(hasOverlays input);

  /**
  Return whether an input is nixpkgs-like infrastructure only.

  # Type

  ```nix
  isNixpkgsInfrastructure :: AttrSet -> Bool
  ```

  # Dependencies

  - flakes.isNixpkgsLike
  - flakes.hasModules
  - flakes.hasOverlays
  */
  isNixpkgsInfrastructure = input:
    isNixpkgsLike input
    && !(hasModules input)
    && !(hasOverlays input);
in
  exports
