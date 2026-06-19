{
  attrsets,
  lists,
  ...
}: let
  exports = {
    scoped = {
      inherit
        collectModules
        preferDefaultModules
        getPackages
        ;
    };

    global = {
      # collectModules = collect;
      # preferDefaultModules = preferDefault;
    };
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
  exports
