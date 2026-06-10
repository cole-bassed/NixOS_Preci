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

  inherit ((import ./attrsets.nix).scoped) update;

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
  mkDots = args @ {
    flake ? {},
    paths ? {},
    host ? {},
  }: {
    ${flake.name or args.name or "dots"} =
      update (update (removeAttrs ["path"] flake) {
        paths = update paths {
          store = toString (flake.path or (
            paths.src or (
              args.src or ../../.
            )
          ));
          local =
            host.paths.src or (
              paths.host.src or (
                args.host.src or "Undefined Local Path"
              )
            );
        };
      })
      args;
  };
in
  exports
