{lix, ...}: let
  inherit (lix.treefmt) evalModule projectRoot;
  inherit (lix.systems) forEachSystem;

  eval = pkgs:
    evalModule pkgs (import ./config.nix);
in {
  formatter =
    forEachSystem
    (pkgs: (eval pkgs).config.build.wrapper);
  checks =
    forEachSystem
    (pkgs: {formatting = (eval pkgs).config.build.check projectRoot;});
}
