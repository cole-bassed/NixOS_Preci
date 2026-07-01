{
  lix,
  top,
  path,
  ...
}: let
  inherit (lix.modules) mkIf mkMerge;
  inherit (lix.options) mkEnableOption mkModuleArgs mkOption;
  inherit (lix.types) str;

  mkArgs = config: pkgs: scope: mkModuleArgs {inherit config top path pkgs scope;};
  shouldEnable = config: cfg: (config ? programs.niri) && cfg.enable;
in {
  core = {};
  home = {};
  # core = {
  #   config,
  #   pkgs,
  #   ...
  # }: let
  #   inherit (lix.lists) elem;
  #   isManaged = config: elem "niri" config.${top}.interface.backend.managers;
  #   inherit ((mkArgs config pkgs "core")) cfg opt;
  # in {
  #   options = opt {enable = mkEnableOption "Niri compositor" // {default = isManaged config;};};
  #   config = mkIf (shouldEnable config cfg) {
  #     programs = {
  #       niri = {
  #         enable = true;
  #         package = pkgs.niri;
  #       };
  #       uwsm.waylandCompositors.niri = {
  #         prettyName = "Niri";
  #         comment = "Niri compositor managed by UWSM";
  #         binPath = "/run/current-system/sw/bin/niri";
  #       };
  #     };
  #   };
  # };
  # home = {
  #   config,
  #   pkgs,
  #   ...
  # }: let
  #   inherit ((mkArgs config pkgs "home")) cfg opt programs;
  # in {
  #   options = opt {
  #     enable = mkEnableOption "Niri compositor";
  #     fallbackConfig = mkOption {
  #       type = str;
  #       default = "${path}/configs/niri/config.kdl";
  #     };
  #   };

  #   config = mkMerge [
  #     (mkIf (shouldEnable config cfg) {inherit programs;})

  #     (mkIf cfg.enable {
  #       xdg.configFile."niri/config.kdl" = {
  #         source = builtins.path {
  #           path = cfg.fallbackConfig;
  #           name = "niri-config";
  #         };
  #       };
  #     })
  #   ];
  # };
}
