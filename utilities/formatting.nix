{
  libraries,
  base,
  ...
}: let
  inherit (libraries.treefmt) evalModule self;
  inherit (libraries.config) forEachSystem;

  evalFor = pkgs:
    evalModule pkgs {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        statix.enable = true;
      };
    };
in {
  formatter = forEachSystem (pkgs: (evalFor pkgs).config.build.wrapper);

  checks = forEachSystem (pkgs: {
    formatting = (evalFor pkgs).config.build.check self;
  });
}
