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
      default = let
        derived = overrides.fallbackConfig or null;
        default = defaults.fallbackConfig or "";
      in
        if derived != null
        then derived
        else default;
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
    options =
      recursiveUpdate
      evaluated.options
      (set.options.module (mkOptions (genAttrs ["fallbackConfig"] apiOr)));
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
    inherit (mod) apiOr set evaluated;
  in {
    imports = [
      ./bindings.nix
      ./options.nix
      ./packages.nix
    ];
    options =
      recursiveUpdate
      evaluated.options
      (set.options.module (mkOptions (genAttrs ["fallbackConfig"] apiOr)));
    inherit (evaluated) config;
  };
}
