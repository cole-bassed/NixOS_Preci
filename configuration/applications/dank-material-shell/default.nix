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

      entryPath = get.names.entry.path;
      target = entryPath ++ ["niri"];
      targetExists = hasAttrByPath target options;
      includesEnable =
        if targetExists
        then attrByPath (entryPath ++ ["niri" "includes" "enable"]) true config
        else true;
    in
      asAttrsIf targetExists (
        setAttrByPath target {
          enableKeybinds = (cfg.needsNiri or false) && !includesEnable;
          enableSpawn = cfg.needsNiri or false;
        }
      );
  }
