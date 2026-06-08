let
  exports = {
    scoped = {
      inherit get;
    };

    global = {
      getPackages = get;
    };
  };

  inherit ((import ./attrsets.nix).scoped) orEmpty;

  /**
  Normalize package exports from a flake-like input.

  Supports both `legacyPackages` and `packages` layouts and always returns
  an attrset. When both exist, `packages` is merged over `legacyPackages`.

  # Type

  ```nix
  get :: AttrSet -> AttrSet
  ```

  # Dependencies

  - attrsets.orEmpty

  # Arguments

  input
  : The flake-like input to inspect.

  # Examples

  ```nix
  get { packages.x86_64-linux.hello = {}; }
  # => { x86_64-linux.hello = {}; }
  ```
  */
  get = input: let
    value = orEmpty input;
  in
    orEmpty (value.legacyPackages or {})
    // orEmpty (value.packages or {});
in
  exports
