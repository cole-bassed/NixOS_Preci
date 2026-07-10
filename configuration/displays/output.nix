{
  lix,
  top,
  path,
  registry,
  entry,
  ...
}: let
  inherit (lix.attrsets) hasAttrByPath optionalAttrs;
  inherit (lix.displays) mkHyprland mkNiri;
  inherit (lix.lists) init;
  inherit (lix.modules) mkDefault mkMerge;
  inherit (lix.options) mkModuleArgs mkOption;
  inherit (lix.types) attrs attrsOf;

  path' = path;

  mkMod = {
    config,
    options ? {},
    pkgs ? {},
    scope ? "core",
    path ? path',
  }: let
    module = mkModuleArgs {
      inherit config options pkgs top scope;
      path = init path;
    };
    cfg = module.get.config.module;
    opt = module.set.options.module;

    hasHyprland =
      (config.programs.hyprland.enable or false)
      || (config.wayland.windowManager.hyprland.enable or false)
      || (config.${top}.interface.backends.hyprland.enable or false);

    hasNiri =
      (config.programs.niri.enable or false)
      || (config.${top}.interface.backends.niri.enable or false);

    outputs = {
      monitors = registry;
      hyprland = optionalAttrs hasHyprland (mkHyprland registry);
      niri = optionalAttrs hasNiri (mkNiri registry);
    };

    fields = {
      monitors = mkOption {
        type = attrsOf entry;
        default = outputs.monitors;
        description = "Resolved, compositor-agnostic output/display layout, keyed by connector name.";
      };
      hyprland = mkOption {
        type = attrs;
        default = outputs.hyprland;
        description = "Resolved Hyprland monitors config; empty when Hyprland is not enabled.";
      };
      niri = mkOption {
        type = attrs;
        default = outputs.niri;
        description = "Resolved Niri outputs config; empty when Niri is not enabled.";
      };
    };
  in {
    inherit cfg fields;
    options = opt fields;
    config = opt {
      monitors = mkDefault fields.monitors.default;
      hyprland = mkDefault fields.hyprland.default;
      niri = mkDefault fields.niri.default;
    };
  };

  mk = scope: {
    config,
    options ? {},
    pkgs ? {},
    ...
  }: let
    mod = mkMod {inherit config options pkgs scope;};
  in {
    inherit (mod) options;
    config = mkMerge [
      mod.config
      (
        if scope == "core"
        then {}
        else
          optionalAttrs (hasAttrByPath ["wayland" "windowManager" "hyprland" "settings"] options) {
            wayland.windowManager.hyprland.settings = mod.cfg.hyprland;
          }
          // optionalAttrs (hasAttrByPath ["programs" "niri" "settings"] options) {
            programs.niri.settings.outputs = mod.cfg.niri;
          }
      )
    ];
  };
in {
  core = mk "core";
  home = mk "home";
}
