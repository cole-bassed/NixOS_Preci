{
  lix,
  top,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.modules) mkDefault mkMerge;
  inherit (lix.options) mkOption;
  inherit (lix.types) enum;

  mk = args: mkArgs ({inherit path;} // args);
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }: let
    inherit (mk {inherit config options pkgs;}) initiated evaluated;
  in {
    inherit (evaluated) options;
    config = mkMerge [
      evaluated.config
      {programs.${initiated.leaf}.withUWSM = initiated.cfg.uwsm.enable;}
    ];
  };

  home = {
    config,
    pkgs,
    ...
  }: let
    scope = "home";
    inherit (mk {inherit config pkgs scope;}) initiated evaluated;
  in {
    options = recursiveUpdate evaluated.options (initiated.opt {
      configType = mkOption {
        type = enum ["hyprlang" "lua"];
        default = "hyprlang";
        description = "Home Manager Hyprland configuration format.";
      };
    });
    config = mkMerge [
      evaluated.config
      {
        ${top}.interface.backends.${initiated.leaf}.configType = mkDefault "hyprlang";
        wayland.windowManager.${initiated.leaf} = {
          enable = config.${top}.interface.backends.${initiated.leaf}.enable or false;
          package = config.${top}.interface.backends.${initiated.leaf}.package or null;
          configType = config.${top}.interface.backends.${initiated.leaf}.configType or "hyprlang";
        };
      }
    ];
  };
}
