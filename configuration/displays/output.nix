{
  lix,
  top,
  host,
  dom,
  entry,
  ...
}: let
  inherit (lix.modules) mkIf;
  inherit (lix.displays) mkHyprland mkNiri;
  inherit (lix.options) mkOption;
  inherit (lix.types) attrsOf;

  hasHyprland = config: (
    config.programs.hyprland.enable or (
      config.wayland.windowManager.hyprland.enable or (
        config.${top}.interface.backends.hyprland.enable or false
      )
    )
  );
  hasNiri = config: (
    config.programs.niri.enable or (
      config.${top}.interface.backends.niri.enable or false
    )
  );

  mk = scope: {config, ...}: let
    displays = config.${top}.${dom} or {};
  in {
    options.${top}.${dom} = mkOption {
      type = attrsOf entry;
      default = host.devices.display or {};
      description = "Output/display layout, keyed by connector name.";
    };

    config =
      if scope == "core"
      then {}
      else {
        wayland.windowManager.hyprland.settings =
          mkIf (hasHyprland config) (mkHyprland displays);
        programs.niri.settings.outputs =
          mkIf (hasNiri config) (mkNiri displays);
      };
  };
in {
  core = mk "core";
  home = mk "home";
}
