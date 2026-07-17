{
  top,
  lix,
  lib,
  dom,
  mod,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lix.options) mkModuleArgs;

  mk = scope: {
    config,
    pkgs,
    ...
  }: let
    module = mkModuleArgs {inherit config top dom mod scope pkgs;};
    opt = module.set.options.module;
    package = module.get.package;
    enable = module.get.config.module.enable or false;
  in {
    options = opt {enable = module.set.enable {default = true;};};
    config = mkIf enable (
      if scope == "core"
      then {environment.systemPackages = [package];}
      else {
        programs.${mod} = {
          inherit enable package;
        };
      }
    );
  };
in {
  core = mk "core";
  home = mk "home";
}
