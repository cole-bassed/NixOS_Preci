{
  lix,
  top,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.options) mkModuleArgs;

  mk = scope: {config, ...}: let
    module = mkModuleArgs {inherit config top dom mod scope;};
    cfg = module.get.config.module;
    opt = module.set.options.module;
    enable = cfg.enable or false;
  in {
    options = opt {enable = module.set.enable {default = false;};};
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
