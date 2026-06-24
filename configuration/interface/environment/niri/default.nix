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
      programs = {
        niri = mkIf cfg.niri.enable {
          inherit (cfg.niri) enable;
        };

        uwsm.waylandCompositors.niri = mkIf cfg.niri.enable {
          prettyName = "Niri";
          comment = "Niri compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/niri-session";
        };
      };
    };
  };

  home = {config, ...}: let
    cfg = env config;
  in {
    config = {
      programs.niri = mkIf cfg.niri.enable {
        inherit (cfg.niri) enable;
      };
    };
  };
}
