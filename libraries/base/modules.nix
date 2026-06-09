let
  exports = {
    scoped = {
      inherit
        collect
        preferDefault
        ;
    };

    global = {
      collectModules = collect;
      preferDefaultModules = preferDefault;
    };
  };

  inherit ((import ./attrsets.nix).scoped) get has maps valuesOf;
  inherit ((import ./lists.nix).scoped) asIf concat unique;

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
  preferDefault = modules:
    if modules ? default
    then [modules.default]
    else valuesOf modules;

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
  collect = type: modules: let
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
          valuesOf (
            maps
            (
              _: input: let
                mods =
                  if has "homeModules" input
                  then input.homeModules
                  else input.homeManagerModules or {};
              in
                preferDefault mods
            )
            modules
          )
        )
      else
        concat (
          valuesOf (
            maps
            (
              _: input:
                asIf
                (has moduleAttr input)
                (preferDefault (get moduleAttr input))
            )
            modules
          )
        );
  in
    unique rawCollected;
in
  exports
