{
  attrsets,
  lists,
  strings,
  ...
}: let
  exports = {
    scoped = {
      inherit mkHyprland mkNiri isRequired;
    };
    global = {
      mkHyprlandDisplays = mkHyprland;
      mkNiriDisplays = mkNiri;
    };
  };

  inherit (attrsets) mapAttrs mapAttrsToList optionalAttrs;
  inherit (lists) any elemAt;
  inherit (strings) splitString toInt;

  isRequired = config:
    any (x: x) [
      (config.compositors.hyprland.enable or false)
      (config.compositors.niri.enable or false)
    ];

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
