{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) genAttrs recursiveUpdate;
  inherit (lix.modules) mkMerge;
  inherit (lix.options) mkOption;
  inherit (lix.types) enum;

  mk = args: mkArgs ({inherit path;} // args);
  defaults = {
    configType = "lua";
  };

  mkOptions = overrides: {
    configType = mkOption {
      type = enum ["hyprlang" "lua"];
      default = overrides.configType or defaults.configType;
      description = "Home Manager Hyprland configuration format.";
    };
  };
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }: let
    inherit (mk {inherit config options pkgs defaults;}) get set;
    # inherit (args) apiOr set evaluated cfg mod;
  in {
    options =
      recursiveUpdate
      evaluated.options
      (set.options.module (mkOptions (genAttrs ["configType"] apiOr)));
    config = mkMerge [
      evaluated.config
      {programs.${mod} = {withUWSM = cfg.uwsm.enable;};}
    ];
  };

  home = {
    config,
    options,
    pkgs,
    osConfig ? {},
    ...
  }: let
    scope = "home";
    mod = mk {inherit config osConfig options pkgs scope defaults;};
    inherit (mod) apiOr get set evaluated;
    cfg = get.config.module;
    inherit (get) name;
  in {
    options =
      recursiveUpdate
      evaluated.options
      (set.options.module (mkOptions (genAttrs ["configType"] apiOr)));
    config = mkMerge [
      evaluated.config
      {wayland.windowManager.${name}.configType = cfg.configType;}
    ];
  };
}
