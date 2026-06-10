{
  bootstrap ? import ../base,
  defaults ? {allowUnfree = true;},
  inputs ? {},
  names ? {src = "dots";},
  name ? null,
  paths ? {store.src = ../../.;},
  path ? null,
}: let
  inherit (bootstrap.types) optionalAttrs;

  args = {
    inherit bootstrap defaults;
    names =
      names // optionalAttrs (name != null) {src = name;};

    paths = let
      raw = paths.store or paths;
      merged = raw // optionalAttrs (path != null) {src = path;};
    in {store = merged;};

    inputs = import ./inputs.nix {
      inherit bootstrap defaults inputs names;
    };
  };

  libraries = import ./libraries.nix args;
  modules = import ./modules.nix args;
  overlays = import ./overlays.nix args;
  packages = import ./packages.nix args;
in {
  inherit (args) defaults inputs names paths;
  inherit libraries modules overlays packages;
}
