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

  defaults = {
    configType = "lua";
  };
  mk = args: mkArgs ({inherit path defaults;} // args);

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
    args = mk {inherit config options pkgs;};
    inherit (args) resolvedOr opt cfg evaluated name;
  in {
    options =
      recursiveUpdate
      evaluated.options
      (opt (mkOptions (genAttrs ["configType"] resolvedOr)));
    config = mkMerge [
      evaluated.config
      {programs.${name} = {withUWSM = cfg.uwsm.enable;};}
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
    inherit (mod) resolvedOr get set evaluated;
    cfg = get.config.module;
    inherit (get) name;
  in {
    options =
      recursiveUpdate
      evaluated.options
      (set.options.module (mkOptions (genAttrs ["configType"] resolvedOr)));
    config = mkMerge [
      evaluated.config
      {wayland.windowManager.${name}.configType = cfg.configType;}
    ];
  };
}
