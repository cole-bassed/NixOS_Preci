{
  attrsets,
  lists,
  strings,
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

  inherit (attrsets) mapAttrs mapAttrsToList optionalAttrs;
  inherit (lists) any elemAt;
  inherit (strings) splitString toInt;

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
      ++ (
        with cfg.desktopEnvironment; [
          (gnome.enable or false)
          (plasma.enable or false)
        ]
      )
      ++ (
        with cfg.windowManagement; [
          (hyprland.enable or false)
          (niri.enable or false)
        ]
      ));

  mkHyprland = displays:
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
        position =
          if display.position != null
          then display.position
          else "auto";
        scale = toString display.scale;
      in "${name}, ${resolution}${refreshRate}, ${position}, ${scale}"
    )
    displays;

  mkNiri = displays:
    mapAttrs (name: display:
      optionalAttrs display.enable (
        {}
        // optionalAttrs (display.resolution != null && display.refreshRate != null) {
          mode = {
            #TODO: Refactor for width and height
            width = toInt (elemAt (splitString "x" display.resolution) 0);
            height = toInt (elemAt (splitString "x" display.resolution) 1);
            refresh = display.refreshRate * 1000.0;
          };
        }
        // optionalAttrs (display.position != null) {
          position = {
            #TODO: Refactor for x and y, same function as width and height
            x = toInt (elemAt (splitString "x" display.position) 0);
            y = toInt (elemAt (splitString "x" display.position) 1);
          };
        }
        // {
          scale = display.scale;
        }
      ))
    displays;
in
  exports
