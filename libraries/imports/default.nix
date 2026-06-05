libraries: let
  lib = libraries.nixpkgs or (import <nixpkgs/lib>);
  nixpkgs = lib // (import ./nixpkgs.nix {inherit lib;});
in
  nixpkgs
  // libraries
  // {libraries = libraries // {inherit nixpkgs;};}
