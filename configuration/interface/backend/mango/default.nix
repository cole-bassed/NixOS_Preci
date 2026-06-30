{
  lix,
  top,
  dom,
  mod,
  leaf,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.options) mkModuleArgs;

  mkArgs = config: scope:
    mkModuleArgs {inherit config top dom mod scope;};
in {
  core = {config, ...}: let
    inherit ((mkArgs config "core")) cfg;
  in {
    config = {
      programs = {
        ${leaf} = mkIf cfg.${leaf}.enable {
          enable = true;
        };
      };
    };
  };

  home = _: {
    config = {};
  };
}
