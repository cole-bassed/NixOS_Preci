{
  lix,
  top,
  path,
  backendsOf,
  ...
}: let
  name = "niri";
  prettyName = "Niri";
  bin = name;

  inherit (lix.options) mkEnableOption mkModuleArgs mkOption;
  inherit (lix.types) str;
  inherit (lix.assembly) mkCfgIf;
  inherit (lix.lists) elem;

  mkArgs = config: pkgs: scope: mkModuleArgs {inherit config top path pkgs scope;};
in {
  core = {
    config,
    pkgs,
    host,
    ...
  }: let
    inherit ((mkArgs config pkgs "core")) cfg opt;
  in {
    options = opt {
      enable =
        mkEnableOption "Niri compositor"
        // {
          default = elem name (backendsOf host);
        };
    };

    config = mkCfgIf {inherit cfg;} {
      programs = {
        niri.enable = true;
        uwsm.waylandCompositors.niri = {
          prettyName = "Niri";
          comment = "Niri compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/niri";
        };
      };
    };
  };

  home = {
    config,
    pkgs,
    user,
    ...
  }: let
    inherit ((mkArgs config pkgs "home")) cfg opt;
  in {
    options = opt {
      enable =
        mkEnableOption "Niri compositor"
        // {
          default = elem name (backendsOf user);
        };
      fallbackConfig = mkOption {
        type = str;
        default = "${path}/configs/niri/config.kdl";
      };
    };

    config = mkCfgIf {inherit cfg;} {
      programs.niri.settings = {};
    };
  };
}
