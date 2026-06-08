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

  inherit
    (builtins)
    attrValues
    concatLists
    getAttr
    hasAttr
    mapAttrs
    ;

  inherit ((import ./lists.nix).scoped) unique;

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
        concatLists (
          attrValues (
            mapAttrs
            (
              _: input: let
                mods =
                  if hasAttr "homeModules" input
                  then input.homeModules
                  else input.homeManagerModules or {};
              in
                preferDefault mods
            )
            modules
          )
        )
      else
        concatLists (
          attrValues (
            mapAttrs
            (
              _: input:
                lists.scoped.asIf
                (hasAttr moduleAttr input)
                (preferDefault (getAttr moduleAttr input))
            )
            modules
          )
        );
  in
    unique rawCollected;
in
  exports
