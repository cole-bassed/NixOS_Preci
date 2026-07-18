{
  lix,
  top,
  path,
  ...
}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.modules) mkMerge mkIf mkModuleArgs mkBackendOptions;
  inherit (lix.options) mkEnableOption mkOption;
  inherit (lix.types) enum;
  inherit (import ./actions.nix {inherit lix;}) mkActions;
  mk = scope: {
    config,
    options,
    pkgs,
    osConfig ? {},
    ...
  }: let
    mod = mkModuleArgs {inherit config top path pkgs options osConfig scope;};
    inherit (mod) get set;
    inherit (get) apiOr cfg name prettyName;
    inherit (set) opt;
    backend = mkBackendOptions {inherit get set scope options top;};
  in {
    options =
      recursiveUpdate
      backend.options
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
        enableAddons =
          mkEnableOption "Whether to enable sane ${prettyName} addons"
          // {default = true;};
        enableRules =
          mkEnableOption "Whether to enable sane ${prettyName} window rules"
          // {default = true;};
        semanticKeybinds =
          mkEnableOption "modular semantic keybind layer for ${prettyName}"
          // {default = true;};
        actions = mkActions;
      });
    config = mkMerge [
      backend.config
      (mkIf (cfg.enable or false) (
        if scope == "core"
        then {programs.${name} = {withUWSM = cfg.uwsm.enable;};}
        else {
          wayland.windowManager.${name} = mkMerge [
            {
              # imports = [./settings ./submaps];
              inherit (cfg) configType;
            }
            (import ./settings {inherit lix cfg;})
            # (import ./submaps)
          ];
        }
      ))
    ];
    imports =
      if scope == "home"
      then [./addons ./bindings.nix]
      else [];
  };
in {
  core = mk "core";
  home = mk "home";
}
