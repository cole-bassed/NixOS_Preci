{
  defaults ? {allowUnfree = true;},
  flake ? {},
  inputs ? {},
  name ? null,
  names ? {src = "dots";},
  path ? null,
  paths ? {},
}: let
  paths' = {
    src = paths.src or ../../.;
    bootstrap = paths.bootstrap or ../internal/base;
  };
  bootstrap = import paths'.bootstrap {paths = paths';};
  inherit (bootstrap.attrsets) merge;
  inherit (bootstrap.types) isFlakeLike isAttrs;
  inherit (bootstrap.config) getEnv;

  args = {
    inherit bootstrap;
    inherit (resolved) inputs;

    defaults = merge defaults (
      merge {
        host = let
          env = {
            host = getEnv "HOSTNAME";
            name = getEnv "NAME";
          };
        in
          if isAttrs flake && (flake.currentHost or "") != ""
          then flake.currentHost
          else if env.host != ""
          then env.host
          else if env.name != ""
          then env.name
          else "ExampleHost";

        excludes = {
          paths = [
            "archive"
            "backup"
            "review"
            "temp"

            "default.nix"
            "flake.nix"
          ];
        };

        tags = ["core" "home"];
      } (flake.defaults or {})
    );

    names = merge names (
      merge {
        src =
          if name != null
          then name
          else names.src;
      }
      (flake.names or {})
    );

    paths = merge (merge paths paths') (
      merge {
        store.src =
          if path != null
          then path
          else paths.src;
      } (flake.paths or{})
    );

    path = args.paths.store.src;
    name = args.names.src;
  };

  common = {
    inherit (args) defaults names paths;
    inherit (resolved) libraries;
  };

  resolved = {
    inputs = import ./inputs.nix {
      inputs = flake.inputs or inputs;
      inherit (args) bootstrap defaults name;
    };
    libraries = import ./libraries.nix args;
    modules = import ./modules.nix args;
    overlays = import ./overlays.nix args;
    packages = import ./packages.nix args;
  };

  src = {
    inherit common;
    flake = common // resolved;
  };
in
  {inherit (args) defaults names paths;}
  // resolved.libraries.merged
  // (
    if (isFlakeLike resolved.inputs)
    then {
      inherit (src) flake;
      ${args.names.src} = src.flake;
    }
    else {${args.names.src} = src.common;}
  )
