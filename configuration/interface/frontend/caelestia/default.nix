{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) hasAttrByPath optionalAttrs setAttrByPath;
  inherit (lix.lists) findFirst;
  inherit (lix.modules) mkMerge;

  mk = args: mkArgs ({inherit path;} // args);

  mkTargetConfig = {
    targets,
    options,
    enabled,
  }: let
    target = findFirst (candidate: hasAttrByPath candidate options) null targets;
    hasSub = key: target != null && hasAttrByPath (target ++ [key]) options;
    frontendCfg = optionalAttrs (hasSub "enable") {enable = enabled;};
  in
    optionalAttrs (target != null && frontendCfg != {}) (setAttrByPath target frontendCfg);
in {
  core = {
    config,
    options,
    pkgs,
    ...
  }: let
    inherit (mk {inherit config options pkgs;}) initiated evaluated;
    enabled = (config.${initiated.top}.interface.frontend.selected or null) == initiated.name;
  in {
    inherit (evaluated) options;
    config = mkMerge [
      evaluated.config
      (mkTargetConfig {
        inherit options enabled;
        targets = [
          ["programs" "caelestia-shell"]
          ["programs" "caelestia"]
        ];
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
    inherit (mk {inherit config options pkgs scope;}) initiated evaluated;
    enabled = (config.${initiated.top}.interface.frontend.selected or null) == initiated.name;
  in {
    inherit (evaluated) options;
    config = mkMerge [
      evaluated.config
      (mkTargetConfig {
        inherit options enabled;
        targets = [
          ["programs" "caelestia-shell"]
          ["programs" "caelestia"]
        ];
      })
    ];
  };
}
