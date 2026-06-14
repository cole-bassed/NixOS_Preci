{
  bootstrap ? import ./base,
  external ? import ../external {},
  paths ? {},
  defaults ? {},
  names ? {},
}: let
  inherit (bootstrap.attrsets) recursiveAttrs;
  inherit (bootstrap.config) mkLibs recursiveSelf;
  inherit (bootstrap.types) isAttrs isPath isString typeOf;

  flake = external.flake or {};

  resolved = {
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
      (flake.defaults or {})
    );

    paths = recursiveAttrs paths (
      recursiveAttrs {
        store = {
          src = ../../.;
          api = ../../configuration/api;
        };
        local.src = "/etc/nixos";
      }
      (flake.paths or {})
    );

    names = recursiveAttrs names (
      recursiveAttrs {
        src = "dots";
        lib = "lix";
        top = "_";
      }
      (flake.names or {})
    );
  };

  libraries = recursiveSelf (libraries:
    mkLibs {
      libraries =
        recursiveAttrs
        (recursiveAttrs external bootstrap)
        (
          libraries
          // {
            inherit (resolved) defaults names paths;
            flake = flake;
            external = external;
          }
        );

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
    });
  # global = foldl' (acc: name: acc // (scoped.${name}.global or {})) {} [
  #   "api"
  #   "attrsets"
  #   "debug"
  #   "filesystem"
  #   "lists"
  #   "options"
  #   "strings"
  #   "types"
  #   "config"
  # ];
in
  libraries
  // {
    lib = external;
    "${resolved.names.lib}" = libraries;
  }
