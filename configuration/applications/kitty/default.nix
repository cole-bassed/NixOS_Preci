{
  lix,
  top,
  pkgs,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.options) mkModuleArgs;

  mk = scope: {config, ...}: let
    module = mkModuleArgs {inherit config top dom mod scope pkgs;};
    cfg = module.get.config.module;
    opt = module.set.options.module;
    package = module.get.package;
    enable = cfg.enable or false;
  in {
    options = opt {enable = module.set.enable {default = false;};};
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
