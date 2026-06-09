let
  exports = {
    scoped = {
      inherit mkDots;
      inherit (builtins) getEnv;
      inherit ((import ./modules.nix).scoped) collect preferDefault;
      inherit ((import ./packages.nix).global) getPackages;
    };

    global = {
      inherit mkDots;
    };
  };

  /**
  Build the basic `dots` path configuration for a host.

  # Type

  ```nix
  mkDots :: AttrSet -> AttrSet -> AttrSet
  ```

  # Dependencies

  None

  # Arguments

  paths
  : Project paths. Must include `src`.

  host
  : Host config. Must include `paths.src`.

  # Examples

  ```nix
  mkDots { src = ./.; } { paths.src = /home/me/dots; }
  # => { dots = { store = "..."; local = /home/me/dots; }; }
  ```
  */
  mkDots = paths: host: {
    dots = {
      store = toString paths.src;
      local =
        host.paths.src
        or (throw "config.mkDots:= host must define 'paths.src'");
    };
  };
in
  exports
