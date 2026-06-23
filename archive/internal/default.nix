{
  external ? null,
  bootstrap ? null,
  flake ? {},
  paths ? {},
  defaults ? {},
  names ? {},
}: let
  bib =
    if bootstrap != null
    then bootstrap
    else
      import (
        paths.store.libraries.bootstrap or
       (paths.bootstrap or ../bootstrap.nix)
      );

  lib =
    if external != null
    then external
    else
      import (
        paths.store.libraries.external or
        (paths.external or ../external)
      ) {
        inherit defaults flake names paths;
      };

  inherit (bib) recursiveAttrs mkLibs mkPaths;
  inherit (builtins) isAttrs isPath isString typeOf;

  resolved = {
    bootstrap = bib;
    external = lib;
    flake = resolved.external.flake or flake;

    defaults = recursiveAttrs defaults (
      recursiveAttrs {
        host = "TheExample";
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

    paths = mkPaths {
      paths = recursiveAttrs paths (
        recursiveAttrs {
          store = {
            src = ../../.;
            api = ../../configuration/api;
          };
          local.src = "/etc/nixos";
        }
        (resolved.flake.paths or {})
      );
    };

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
        inherit (resolved) flake;
        inherit (resolved) external;
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
          inherit (arg) input;
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
  resolved
  // libraries
  // {
    lib = external;
    "${resolved.names.lib}" = libraries;
  }
# removePaths (recursiveAttrs external internal) [
#   {
#     scopes = [
#       "lib"
#       "lists"
#       "modules"
#     ];
#     items = [
#       "applyModuleArgsIfFunction"
#       "collectModules"
#       "dischargeProperties"
#       "evalOptionValue"
#       "fold"
#       "isInOldestRelease"
#       "mergeModules'"
#       "mergeModules"
#       "mkAliasOptionModuleMD"
#       "mkFixStrictness"
#       "nixpkgsVersion"
#       "pushDownProperties"
#       "unifyModuleSyntax"
#     ];
#   }
# ]
