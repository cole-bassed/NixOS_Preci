{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) genAttrs recursiveUpdate;
  inherit (lix.lists) optional;
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
    inherit (mk {inherit config options pkgs defaults;}) apiOr set evaluated;
  in {
    imports = [./options.nix];
    options = recursiveUpdate evaluated.options (set.options.module (mkOptions (genAttrs ["fallbackConfig"] apiOr)));
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
    inherit (mod) apiOr cfgOr set evaluated;
    keybindsModule = args:
      import ./keybinds.nix ({
          niriEnable = (cfgOr "enable") == true;
          niriSemanticKeybinds = (cfgOr "semanticKeybinds") == true;
          niriActions = let
            actions = cfgOr "actions";
          in
            if actions == null then {} else actions;
        }
        // args);
  in {
    imports = [
      ./options.nix
      ./packages.nix
      keybindsModule
    ];
    options =
      recursiveUpdate
      evaluated.options
      (set.options.module (mkOptions (genAttrs ["fallbackConfig"] apiOr)));
    inherit (evaluated) config;
  };
}
