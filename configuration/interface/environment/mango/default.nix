{
  lix,
  top,
  dom,
  mod,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs;

  args = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};

  env = config:
    config.${top}.${dom}.environment;
in {
  core = {config, ...}: let
    cfg = env config;
  in {
    config = {
      programs.mango = mkIf cfg.mango.enable {
        enable = true;
      };
    };
  };

  home = {config, ...}: {
    config = {};
  };
}
