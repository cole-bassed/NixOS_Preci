{
  external ? null,
  flake ? {},
  paths ? {},
  defaults ? {},
  names ? {},
}: let
  paths' = {
    src = paths.src or ../../.;
    libraries = {
      bootstrap = paths.libraries.bootstrap or(paths.bootstrap or ./base);
      external = paths.libraries.external or  (paths.external or ../external);
      internal = paths.libraries.internal or  (paths.internal or ./.);
    };
  };
  bootstrap = import paths'.libraries.bootstrap {paths = paths';};
  inherit (bootstrap.attrsets) recursiveAttrs;
  inherit (bootstrap.config) mkLibs recursiveSelf;
  inherit (bootstrap.types) isAttrs isPath isString typeOf;

  resolved = {
    external =
      if external != null
      then external
      else
        import paths'.libraries.external {
          inherit defaults flake names;
          paths = recursiveAttrs (paths paths');
        };

    flake = resolved.external.flake or flake;

    defaults = recursiveAttrs defaults (
      recursiveAttrs {
        host = "ExampleHost";
        excludes.paths = [
          "archive"
          "backup"
          "review"
          "temp"
          "default.nix"
          "flake.nix"
        ];
        tags = ["core" "home"];
      }
      (resolved.flake.defaults or {})
    );

    paths = recursiveAttrs (recursiveAttrs paths paths') (
      recursiveAttrs {
        store = {
          src = ../../.;
          api = ../../configuration/api;
        };
        local.src = "/etc/nixos";
      }
      (resolved.flake.paths or {})
    );

    names = recursiveAttrs names (
      recursiveAttrs {
        src = "dots";
        lib = "lix";
        top = "_";
      }
      (resolved.flake.names or {})
    );
  };

  libraries = mkLibs {
    seed =
      recursiveAttrs
      (recursiveAttrs external bootstrap)
      {
        inherit (resolved) defaults names paths;
        flake = resolved.flake;
        external = resolved.external;
      };
    specs = let
      mk = arg: let
        dependencies = [
          "api"
          "attrsets"
          "config"
          "debug"
          "defaults"
          "environment"
          "external"
          "flake"
          "lists"
          "names"
          "options"
          "paths"
          "strings"
          "systems"
          "types"
        ];
      in
        if isPath arg || isString arg
        then {
          input = arg;
          output = [];
          inherit dependencies;
        }
        else if isAttrs arg
        then {
          input = arg.input;
          output = arg.output or [];
          dependencies = arg.dependencies or dependencies;
        }
        else abort "mk: Expected path, string, or attrset. Got ${typeOf arg}";
    in [
      (mk {
        input = resolved.paths.store.api;
        output = ["api"];
      })
      (mk ./attrsets.nix)
      (mk ./debug.nix)
      (mk ./filesystem.nix)
      (mk ./lists.nix)
      (mk ./options.nix)
      (mk ./strings.nix)
      (mk ./types.nix)
      (import ./config)
    ];
  };
in
  libraries
  // {
    lib = external;
    "${resolved.names.lib}" = libraries;
  }
