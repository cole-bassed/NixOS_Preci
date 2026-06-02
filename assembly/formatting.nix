{
  treefmt,
  perSystem,
  ...
}: let
  fmt = pkgs:
    treefmt.evalModule pkgs {
      projectRootFile = "flake.nix";

      programs = {
        alejandra.enable = true; # Global nixpkgs formatting style
        statix.enable = true; # Lints layouts and fixes anti-patterns
      };
    };
in {
  # Exposes outputs.formatter.${system}
  formatter = perSystem (pkgs: (fmt pkgs).config.build.wrapper);

  # Exposes outputs.checks.${system}.formatting
  checks = perSystem (pkgs: {formatting = (fmt pkgs).config.build.check;});
}
