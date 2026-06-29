{
  lib,
  mod,
  packages,
  mkArgs,
  ...
}: let
  name = "lfs";
  inherit (lib.modules) mkDefault mkIf;
in {
  core = {config, ...}: let
    scope = "core";
    inherit (mkArgs {inherit config scope;}) cfg;
  in {
    config = mkIf cfg.enable {environment.systemPackages = [packages.${name}];};
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) cfg;
  in {
    config = mkIf cfg.enable {
      programs.${mod}.${name}.enable = mkDefault true;
    };
  };
}
