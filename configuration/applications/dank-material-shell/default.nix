{
  lix,
  top,
  path,
  ...
}: let
  inherit (lix.attrsets) asAttrsIf attrByPath hasAttrByPath setAttrByPath;
  inherit (lix.modules) mkProgramToggle;
  inherit (lix.options) mkEnableOption;
  inherit (lix.lists) elem;
  inherit (lix.types) isList isString;
in
  mkProgramToggle {
    inherit top path;

    extraOptions = mod: let
      inherit (mod) config get;
      name = get.names.name;
    in {
      isRequired =
        mkEnableOption "Whether ${name} is selected by the host or user"
        // {
          default = let
            target = config.parent.selected or null;
          in
            if isList target
            then elem name target
            else if isString target
            then target == name
            else false;
        };

      needsNiri =
        mkEnableOption "Whether ${name} requires Niri integration"
        // {default = config.domain.backends.niri.enable or false;};
    };

    extraHomeConfig = mod: let
      inherit (mod) config cfg get options;

      target = get.names.entry.path ++ ["niri"];
      targetExists = hasAttrByPath target options.main;
      includesEnable =
        if targetExists
        then attrByPath (target ++ ["includes" "enable"]) true config
        else true;
    in
      asAttrsIf targetExists (setAttrByPath target {
        includes.enable = cfg.needsNiri or false;
        enableKeybinds = (cfg.needsNiri or false) && !includesEnable;
        enableSpawn = cfg.needsNiri or false;
      });
  }
