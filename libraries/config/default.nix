{bootstrap, ...}: let
  inherit (bootstrap.config) mkLibrary;
  base = ./.;
in
  mkLibrary {
    inherit base;
    excludes = ["default"];
    seed = {inherit bootstrap;};
    enableAliases = false;
    enableExtras = false;
  }
