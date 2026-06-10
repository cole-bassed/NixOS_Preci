{
  bootstrap ? import ../base,
  defaults ? {allowUnfree = true;},
  flake ? {},
  inputs ? {},
  name ? null,
  names ? {src = "dots";},
  path ? null,
  paths ? {},
}: let
  inherit (bootstrap.attrsets) asAttrsIf merge;
  inherit (bootstrap.types) isFlakeLike isAttrs;
  inherit (bootstrap.config) getEnv;

  args = {
    inherit bootstrap;
    inherit (resolved) inputs;

    defaults = merge {
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
    } (merge defaults (flake.defaults or {}));

    names = names // asAttrsIf (name != null) {src = name;};

    paths = let
      local = paths.local or {src = "/etc/nixos";};
      store =
        (paths.store or {src = ../../.;})
        // asAttrsIf (path != null) {src = path;};
    in {inherit store local;};

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
  resolved.libraries.merged
  // (
    if (isFlakeLike resolved.inputs)
    then {
      inherit (src) flake;
      ${args.name} = src.flake;
    }
    else {${args.name} = src.common;}
  )
