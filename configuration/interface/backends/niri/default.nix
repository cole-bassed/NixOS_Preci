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

  mk = args: mkArgs ({inherit path;} // args);
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }: let
    inherit (mk {inherit config options pkgs;}) evaluated;
  in {
    inherit (evaluated) options config;
  };

  home = {
    config,
    pkgs,
    ...
  }: let
    scope = "home";
    inherit (mkArgs {inherit config path pkgs scope;}) opt cfg;
  in {
    options = opt (
      (mkEnable {inherit name prettyName config pkgs scope;})
      // {
        fallbackConfig = mkOption {
          type = str;
          default = "config/niri/config.kdl";
          description = "Path to Niri fallback KDL configuration.";
        };
      }
    );
    config = mkCfgIf {inherit cfg;} {
      programs.${name}.settings = {};
    };
  };
}
