{
  lix,
  path,
  mkArgs,
  registry ? {},
  ...
}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.modules) mkMerge mkIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) enum;

  defaults = {
    configType = "hyprlang";
  };

  mk = scope: {
    config,
    options,
    pkgs,
    osConfig ? {},
    ...
  }: let
    inherit (mkArgs {inherit config defaults options osConfig path pkgs scope;}) evaluated get set;
    inherit (get) apiOr cfg name;
    inherit (set) opt;
  in {
    options =
      recursiveUpdate
      evaluated.options
      (opt {
        configType = mkOption {
          type = enum ["hyprlang" "lua"];
          default = let
            derived = apiOr "configType";
            default = defaults.configType;
          in
            if derived != null
            then derived
            else default;
          description = "Home Manager Hyprland configuration format.";
        };
        test = mkOption {
          # default = get.dataEntry or (get.registry or registry);
          default = get.dataEntry or null;
          description = "Home Manager Hyprland configuration format.";
        };
      });

    config = mkMerge [
      evaluated.config
      (mkIf (cfg.enable or false) (
        if scope == "core"
        then {programs.${name} = {withUWSM = cfg.uwsm.enable;};}
        else {wayland.windowManager.${name}.configType = cfg.configType;}
      ))
    ];
  };
in {
  core = mk "core";
  home = mk "home";
}
