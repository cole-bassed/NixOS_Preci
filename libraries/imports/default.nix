src: let
  libraries = src.flake.libraries or {};

  lib = libraries.nixpkgs or (import <nixpkgs/lib>);
  nixpkgs = lib // (import ./nixpkgs.nix {inherit lib;});
in
  nixpkgs // {libraries = libraries // {inherit nixpkgs;};}
