{
  lib,
  packages,
  mkArgs,
  ...
}: let
  name = "delta";
  inherit (lib.modules) mkDefault mkIf;
in {
  core = {config, ...}: let
    scope = "core";
    inherit (mkArgs {inherit config scope;}) cfg;
  in {
    config = mkIf cfg.enable {environment.systemPackages = [packages.delta];};
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mkArgs {inherit config scope;}) cfg opt mkEnableMod;
  in {
    options = opt {${name}.enable = (mkEnableMod {inherit name;}).true;};
    config = mkIf cfg.enable {
      programs.delta = {
        enable = mkDefault true;
        package = mkDefault packages.delta;
        enableGitIntegration = mkDefault true;
        options = {
          navigate = mkDefault true;
          side-by-side = mkDefault true;
        };
      };
    };
  };
}
