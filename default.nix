{flake ? {}, ...}: let
  names = {
    src = "dots";
    top = "dots";
    lib = "lix";
  };

  paths.store = {
    src = ./.;
    api = ./configuration/api;
    dbg = ./debug;
    documentation = ./documentation;
    configurations = ./configuration/modules;
    templates = ./templates;
    devShells = ./utilities/shells;
    utilities = ./utilities;
    secrets = ./configuration/secrets;
    libraries = ./libraries;
    bootstrap = ./libraries/base;
  };

  bootstrap = import paths.bootstrap;
  inherit (bootstrap.attrsets) is inspect orEmpty update;
  inherit (bootstrap.config) getEnv mkDots;

  defaults = let
    base = {
      host = let
        env = {
          host = getEnv "HOSTNAME";
          name = getEnv "NAME";
        };
      in
        if is flake && (flake.currentHost or "") != ""
        then flake.currentHost
        else if env.host != ""
        then env.host
        else if env.name != ""
        then env.name
        else "ExampleHost";

      excludes = {
        paths = [
          "archive"
          "backup"
          "review"
          "temp"

          "default.nix"
          "flake.nix"
        ];
      };

      tags = ["core" "home"];
    };
  in
    update base (orEmpty flake.defaults);

  libraries = import paths.libraries {
    inherit bootstrap defaults flake names paths;
  };
in
  orEmpty libraries.flake
  // mkDots
  // {
    inherit (libraries) api;
    inherit defaults inspect libraries names paths;
  }
