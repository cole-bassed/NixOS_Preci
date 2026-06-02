{lix, ...}: let
  inherit (lix.treefmt) evalModule;
  inherit (lix.systems) perSystem;
in {
  formatter = perSystem (pkgs:
    (evalModule pkgs {
      projectRootFile = "flake.nix";

      programs = {
        alejandra.enable = true; # Leverages your global nixpkgs formatting style
        # deadnix.enable = true; # Automatically searches and strips unused lets/variables
        statix.enable = true; # Lints code layouts and fixes common anti-patterns
      };
    }).config.build.wrapper);
}
