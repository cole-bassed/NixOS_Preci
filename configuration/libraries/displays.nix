{
  attrsets,
  lists,
  names,
  ...
}: let
  exports = {
    scoped = {inherit mkHyprland mkNiri isRequired;};
    global = {
      mkHyprlandDisplays = mkHyprland;
      mkNiriDisplays = mkNiri;
    };
  };

  inherit (attrsets) filterAttrs mapAttrs mapAttrsToList optionalAttrs;
  inherit (lists) any;

  isRequired = args: let
    config = args.config or args;
    cfg = config.${args.top or (args.scope or names.src)} or {};
  in
    any (x: x) ((
        with config; [
          (services.xserver.qtile.enable or false)
          (services.xserver.xmonad.enable or false)
          (programs.niri.enable or false)
          (wayland.windowManager.hyprland.enable or false)
        ]
      )
      ++ [
        (cfg.desktopEnvironment.gnome.enable or false)
        (cfg.desktopEnvironment.plasma.enable or false)
      ]
      ++ [
        (cfg.windowManagement.hyprland.enable or false)
        (cfg.windowManagement.niri.enable or false)
      ]);

  mkHyprland = displays: {
    monitors =
      mapAttrsToList (
        name: display: let
          resolution =
            if display.resolution != null
            then display.resolution
            else "preferred";

          refreshRate =
            if display.refreshRate != null
            then "@${toString display.refreshRate}"
            else "";

          position = let
            inherit (display.layout.position) x y;
          in "${toString x}x${toString y}";

          scale = toString display.scale;
        in "${name}, ${resolution}${refreshRate}, ${position}, ${scale}"
      )
      (filterAttrs (_: display: display.enable or true) displays);
  };

  mkNiri = displays:
    mapAttrs (_name: display:
      optionalAttrs display.enable (
        {}
        // optionalAttrs (display.resolution != null && display.refreshRate != null) {
          mode = {
            inherit (display.layout.size) width height;
            refresh = display.refreshRate * 1000.0;
          };
        }
        // {
          position = {
            inherit (display.layout.position) x y;
          };

          inherit (display) scale;
        }
      ))
    displays;
in
  exports
