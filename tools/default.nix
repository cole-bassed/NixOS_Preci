{libraries}: (import ./formatting.nix {
  inherit (libraries) treefmt;
  inherit (libraries.config) perSystem;
})
