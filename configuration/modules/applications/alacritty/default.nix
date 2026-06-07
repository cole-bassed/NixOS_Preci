{
  top,
  lix,
  pkgs,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix) mkModuleArgs;

  mk = scope: {config, ...}: let
    _ = mkModuleArgs {inherit config top dom mod scope;};
    inherit (_) cfg opt mkEnableMod;
    package = pkgs.${mod};
    inherit (cfg) enable;
  in {
    options = opt {enable = mkEnableMod.false;};
    config = mkIf enable (
      if scope == "core"
      then {environment.systemPackages = [package];}
      else {programs.${mod} = {inherit enable package;};}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
