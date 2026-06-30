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
          inherit (cfg.${leaf}) enable;
        };

        uwsm.waylandCompositors.${leaf} = mkIf cfg.${leaf}.enable {
          prettyName = "Niri";
          comment = "Niri compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/niri-session";
        };
      };
    };
  };

  home = {config, ...}: let
    inherit ((mkArgs config "home")) cfg;
  in {
    config.programs.niri = mkIf cfg.${leaf}.enable {
      inherit (cfg.${leaf}) enable;
    };
  };
}
