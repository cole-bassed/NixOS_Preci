{
  lix,
  mkChild,
  path,
  ...
}: let
  inherit (lix.attrsets) hasAttrByPath optionalAttrs;
  inherit (lix.options) mkEnableOption;
  inherit (lix.lists) elem;
  inherit (lix.types) isList isString;

  mkOptions = child: {
    isRequired =
      mkEnableOption "Whether this ${child.get.name} is selected by the host or user"
      // {
        default = let
          target = child.get.config.parent.selected;
        in
          if isList target
          then elem child.get.name target
          else if isString target
          then target == child.get.name
          else false;
      };

    needsNiri =
      mkEnableOption "Whether this ${child.get.name} is selected by the host or user"
      // {default = child.get.config.domain.backends.niri.enable or false;};
  };
in {
  core = mkChild {
    inherit path mkOptions;
    target = ["programs" "dms-shell"];
  };

  home = mkChild {
    inherit path mkOptions;
    scope = "home";
    target = ["programs" "dank-material-shell"];
    extraConfig = {
      config,
      cfg,
      enabled,
      options,
      ...
    }: let
      target = ["programs" "dank-material-shell" "niri"];
      targetExists = hasAttrByPath target options;
      includesEnable =
        if targetExists
        then config.programs.dank-material-shell.niri.includes.enable or true
        else true;
    in
      optionalAttrs targetExists {
        programs.dank-material-shell.niri = {
          enableKeybinds = enabled && (cfg.needsNiri or false) && !includesEnable;
          enableSpawn = enabled && (cfg.needsNiri or false);
        };
      };
  };
}
