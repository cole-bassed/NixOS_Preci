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
          mkIf
          config.wayland.windowManager.hyprland.enable
          {monitor = mkHyprland displays;};

        programs.niri.settings.outputs =
          mkIf
          config.programs.niri.enable
          (mkNiri displays);
      };
  };
in {
  core = mk "core";
  home = mk "home";
}
