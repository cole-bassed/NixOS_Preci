{
  lib,
  registry,
  mkArgs,
  ...
}: let
  name = "gitui";
  pkgName = registry.${name}.package;
  inherit (lib.modules) mkDefault mkIf;
in {
  core = {
    config,
    pkgs,
    ...
  }: let
    scope = "core";
    inherit (mkArgs {inherit config scope;}) cfg;
  in {
    config = mkIf cfg.enable {
      environment.systemPackages = [pkgs.${pkgName}];
    };
  };

  home = {
    config,
    pkgs,
    ...
  }: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) cfg opt mkEnableMod;
  in {
    options = opt {${name}.enable = (mkEnableMod {inherit name;}).true;};
    config = mkIf cfg.enable {
      programs.${name} = {
        enable = mkDefault true;
        package = mkDefault pkgs.${pkgName};
      };
    };
  };
}
