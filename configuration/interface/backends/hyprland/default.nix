{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.modules) mkMerge mkIf;
  inherit (lix.options) mkOption;
  inherit (lix.types) enum;

  mk = scope: {
    config,
    options,
    pkgs,
    osConfig ? {},
    ...
  }: let
    inherit (mkArgs {inherit config options osConfig path pkgs scope;}) evaluated get set;
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
            default = "hyprlang";
          in
            if derived != null
            then derived
            else default;
          description = "Home Manager Hyprland configuration format.";
        };
        test = mkOption {
          default = get.dataEntry or null;
          description = "Home Manager Hyprland configuration format.";
        };
      });

    config = mkMerge [
      evaluated.config
      (mkIf (cfg.enable or false) (
        if scope == "core"
        then {programs.${name} = {withUWSM = cfg.uwsm.enable;};}
        else {
          wayland.windowManager.${name} = {
            imports = [./settings ./submaps];
            configType = cfg.configType;
          };
        }
      ))
    ];

    imports =
      if scope == "home"
      then [./addons]
      else [];
  };
in {
  core = mk "core";
  home = mk "home";
}
