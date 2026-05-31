{
  lib,
  packages,
  mkArgs,
  ...
}: let
  name = "jujutsu";
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
    inherit (mkArgs {inherit config scope;}) cfg opt mkEnableMod;
  in {
    options = opt {${name}.enable = (mkEnableMod {inherit name;}).true;};
    config = mkIf cfg.enable {
      programs.${name} = {
        enable = mkDefault true;
        package = mkDefault packages.${name};
      };
    };
  };
}
