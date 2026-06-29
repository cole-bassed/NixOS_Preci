{
  lib,
  inputs,
  top,
  lix,
  pkgs,
  dom,
  mod,
  ...
} @ args: let
  inherit (lib.lists) concatMap;
  inherit (lix.lists) asList;
  inherit (lix) mkModuleArgs;

  mkArgs = {
    config,
    scope,
  }:
    mkModuleArgs {inherit config top dom mod scope;};

  packages = {
    inherit (pkgs) firefoxpwa;
  };

  subArgs = args // {inherit packages mkArgs;};

  collect = tag:
    concatMap (spec: asList (spec.${tag} or null))
    (map (f: import f subArgs) [
      ./general.nix
      ./bookmarks.nix
      ./containers.nix
      ./keyboard.nix
      ./pins.nix
      ./policies.nix
      ./program.nix
      ./search.nix
      ./settings.nix
      ./spaces.nix
      ./style.nix
    ]);
in {
  core = [];
  home = [inputs.zen-browser.homeModules.twilight] ++ collect "home";
}
