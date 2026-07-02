{
  lix,
  top,
  host,
  dom,
  entry,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  # inherit (lix.modules) mkIf;
  inherit (lix.displays) mkHyprland mkNiri;
  inherit (lix.options) mkOption;
  inherit (lix.lists) any;
  inherit (lix.types) attrs attrsOf;

  mk = scope: {config, ...}: let
    hasHyprland = any (x: x) [
      (config.programs.hyprland.enable or false)
      (config.wayland.windowManager.hyprland.enable or false)
      (config.${top}.interface.backends.hyprland.enable or false)
    ];

    hasNiri = any (x: x) [
      (config.programs.niri.enable or false)
      (config.${top}.interface.backends.niri.enable or false)
    ];

    monitors = host.devices.display or {};
    outputs = {
      niri = optionalAttrs hasNiri (mkNiri monitors);
      hyprland = optionalAttrs hasHyprland (mkHyprland monitors);
    };
  in {
    options.${top}.${dom} = {
      monitors = mkOption {
        type = attrsOf entry;
        default = monitors;
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

    config =
      if scope == "core"
      then {}
      else {
        wayland.windowManager.hyprland.settings = outputs.hyprland;
        programs.niri.settings.outputs = outputs.niri;
      };
  };
in {
  core = mk "core";
  home = mk "home";
}
