let
  bootstrap = import ./bootstrap.nix;
  inherit (bootstrap) fix merge mkLibs foldl';

  scoped = fix (libraries:
    mkLibs {
      libraries = merge {inherit bootstrap;} libraries;
      base = {inherit bootstrap;};
      specs = [
        {
          input = ./attrsets.nix;
          dependencies = ["lists" "strings" "types"];
        }
        {
          input = ./config.nix;
          dependencies = ["attrsets" "lists"];
        }
        {
          input = ./debug.nix;
          dependencies = ["attrsets" "types"];
        }
        {
          input = ./filesystem.nix;
          dependencies = ["attrsets" "lists" "strings" "types"];
        }
        {
          input = ./lists.nix;
          dependencies = ["attrsets" "types"];
        }
        {
          input = ./modules.nix;
          dependencies = ["attrsets" "lists"];
        }
        {
          input = ./packages.nix;
          dependencies = ["attrsets"];
        }
        {
          input = ./strings.nix;
          dependencies = ["attrsets" "filesystem" "lists" "types"];
        }
        {
          input = ./types.nix;
          dependencies = ["strings"];
        }
      ];
    });

  global = foldl' (acc: name: acc // (scoped.${name}.global or {})) {} [
    "config"
    "attrsets"
    "debug"
    "filesystem"
    "lists"
    "modules"
    "packages"
    "strings"
    "types"
  ];
in
  {inherit scoped global;}
  // scoped
  // global
