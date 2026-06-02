args: let
  inherit (args.libraries) forEachSystem mkConfigurations treefmt;
in
  (import ./formatting.nix {inherit forEachSystem treefmt;})
  // (mkConfigurations {
    class = "nixos";
    inherit args;
  })
