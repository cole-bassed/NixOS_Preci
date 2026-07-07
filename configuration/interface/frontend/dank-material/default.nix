{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) hasAttrByPath optionalAttrs recursiveUpdate setAttrByPath;
  inherit (lix.modules) mkMerge;
  inherit (lix.options) mkEnableOption;
  inherit (lix.lists) elem;
  inherit (lix.types) isList isString;

  mkOptions = overrides: {};
  mk = args: mkArgs ({inherit path;} // args);

  mkTargetConfig = {
    target,
    options,
    enabled,
  }: let
    hasSub = key: hasAttrByPath (target ++ [key]) options;
    cfg = optionalAttrs (hasSub "enable") {enable = enabled;};
  in
    optionalAttrs (cfg != {}) (setAttrByPath target cfg);
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }: let
    inherit (mk {inherit config options pkgs;}) get evaluated;
    enabled = (get.config.parent.selected or null) == get.name;
  in {
    inherit (evaluated) options;
    config = mkMerge [
      evaluated.config
      (mkTargetConfig {
        inherit options enabled;
        target = ["programs" "dms-shell"];
      })
    ];
  };

  home = {
    config,
    options,
    pkgs,
    ...
  }: let
    scope = "home";
    mod = mk {inherit config options pkgs scope;};
    inherit (mod) get set evaluated;
    enabled = get.config.module.enable or (get.config.module.isRequired or false);
    hasNiri = get.config.domain.backends.niri.enable or false;
  in {
    options =
      recursiveUpdate
      evaluated.options
      (set.options.module ((mkOptions {})
        // {
          isRequired =
            mkEnableOption "Whether this ${get.name} is selected by the host or user"
            // {
              default = let
                target = get.config.parent.selected;
              in
                if isList target
                then elem get.name target
                else if isString target
                then target == get.name
                else false;
            };
          needsNiri =
            mkEnableOption "Whether this ${get.name} is selected by the host or user"
            // {default = hasNiri;};
        }));
    config = mkMerge [
      evaluated.config
      (mkTargetConfig {
        inherit options enabled;
        target = ["programs" "dank-material-shell"];
      })
      {
        programs.dank-material-shell.niri = {
          enableKeybinds = enabled && hasNiri;
          enableSpawn = enabled && hasNiri;
        };
      }
    ];
  };
}
