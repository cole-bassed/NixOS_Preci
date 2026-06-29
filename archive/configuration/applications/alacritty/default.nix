{
  top,
  lix,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix) mkModuleArgs;

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    args = mkModuleArgs {inherit config top dom mod scope;};
    inherit (args) opt mkEnableMod;
    package = pkgs.${mod};
    enable = mkEnableMod.true;
  in {
    options = opt {enable = mkEnableMod.true;};
    config = mkIf enable (
      if scope == "core"
      then {environment.systemPackages = [package];}
      else {inherit (args) programs;}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
