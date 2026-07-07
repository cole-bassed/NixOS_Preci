{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) genAttrs recursiveUpdate;
  inherit (lix.options) mkOption;
  inherit (lix.types) str;

  mk = args: mkArgs ({inherit path;} // args);
  defaults = {
    fallbackConfig = "config/niri/config.kdl";
  };

  mkOptions = overrides: {
    fallbackConfig = mkOption {
      type = str;
      default = overrides.fallbackConfig or defaults.fallbackConfig;
      description = "Path to Niri fallback KDL configuration.";
    };
  };
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }: let
    inherit (mk {inherit config options pkgs;}) set evaluated;
  in {
    options = recursiveUpdate evaluated.options (set.options.module (mkOptions {}));
    inherit (evaluated) config;
  };

  home = {
    config,
    options,
    pkgs,
    osConfig,
    ...
  }: let
    scope = "home";
    mod = mk {inherit config options osConfig pkgs scope defaults;};
    inherit (mod) set evaluated cfgOr;
  in {
    options =
      recursiveUpdate
      evaluated.options
      (set.options.module (mkOptions (genAttrs ["fallbackConfig"] cfgOr)));
    inherit (evaluated) config;
  };
}
