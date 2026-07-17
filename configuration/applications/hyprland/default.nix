{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.modules) mkMerge mkIf;
  inherit (lix.options) mkEnableOption mkOption;
  inherit (lix.types) enum;

  # Same shape as configuration/applications/niri/default.nix's
  # mkActionOption -- see ./actions.nix for the shared definitions, kept
  # in a separate file so it's easy to diff against niri's copy and spot
  # drift between the two backends' action sets.
  inherit (import ./actions.nix {inherit lix;}) mkActions;

  mk = scope: {
    config,
    options,
    pkgs,
    osConfig ? {},
    ...
  }: let
    inherit (mkArgs {inherit config options osConfig path pkgs scope;}) evaluated get set;
    inherit (get) apiOr cfg name prettyName;
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
      evaluated.config
      (mkIf (cfg.enable or false) (
        if scope == "core"
        then {programs.${name} = {withUWSM = cfg.uwsm.enable;};}
        else {
          wayland.windowManager.${name} = mkMerge [
            {
              # imports = [./settings ./submaps];
              configType = cfg.configType;
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
