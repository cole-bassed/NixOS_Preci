{
  lix,
  path,
  mkArgs,
  mkEnable,
  ...
}: let
  name = "niri";
  prettyName = "Niri";

  inherit (lix.modules) mkCfgIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) str;
  mk = config: scope: mkArgs {inherit config path scope;};
in {
  core = {config, ...}: let
    scope = "core";
    inherit (mk config scope) opt cfg;
  in {
    options = opt (mkEnable {inherit name prettyName config scope;}).default;
    config = mkCfgIf {inherit cfg;} {
      programs.${name}.enable = true;
    };
  };

  home = {config, ...}: let
    scope = "home";
    inherit (mk config scope) opt cfg;
  in {
    options = opt (
      (mkEnable {inherit name prettyName config scope;}).default
      // {
        fallbackConfig = mkOption {
          type = str;
          default = "${path}/configs/niri/config.kdl";
          description = "Path to Niri fallback KDL configuration.";
        };
      }
    );

    config = mkCfgIf {inherit cfg;} {
      programs.${name}.settings = {};
    };
  };
}
