flake: let
  path = flake.inputs.self;
  inherit (flake.libraries) forEachSystem mkConfigurations treefmt;
in
  (import ./formatting.nix {inherit forEachSystem treefmt path;})
  // (mkConfigurations {
    class = "nixos";
    inherit flake;
  })
