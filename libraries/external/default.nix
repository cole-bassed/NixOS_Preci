{
  bootstrap ? import ../base,
  defaults ? {allowUnfree = true;},
  inputs ? {},
  names ? {src = "dots";},
  name ? null,
  paths ? {store.src = ../../.;},
  path ? null,
}: let
  inherit (bootstrap.attrsets) asAttrsIf;
  inherit (bootstrap.types) isFlakeLike;

  args = {
    inherit bootstrap defaults;
    names = names // asAttrsIf (name != null) {src = name;};

    paths = let
      raw = paths.store or paths;
      merged = raw // asAttrsIf (path != null) {src = path;};
    in {store = merged;};

    path = args.paths.store.src;
    name = args.names.src;

    inputs = import ./inputs.nix {
      inherit bootstrap defaults inputs;
      inherit (args) names;
    };
  };

  libraries = import ./libraries.nix args;
  modules = import ./modules.nix args;
  overlays = import ./overlays.nix args;
  packages = import ./packages.nix args;

  flake = {
    inherit (args) inputs;
    inherit libraries modules overlays packages;
  };
in
  libraries.merged
  // {
    inherit (args) defaults names paths;
  }
  // asAttrsIf (isFlakeLike args.inputs) {
    inherit flake;
    ${args.names.src} = flake;
  }
