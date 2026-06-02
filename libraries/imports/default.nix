{libraries}: let
  lib = libraries.nixpkgs;
  curated = import ./nixpkgs.nix {inherit lib;}; # TODO: Split into separate files
in
  libraries // {nixpkgs = lib // curated;}
