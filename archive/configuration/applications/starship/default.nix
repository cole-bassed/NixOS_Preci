{
  lix,
  top,
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
    inherit (cfg) enable;
  in {
    options = opt {enable = mkEnableMod.false;};
    config = mkIf enable (
      if scope == "core"
      then {programs.${mod} = {inherit enable;};}
      else {programs.${mod} = {inherit enable;};}
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
