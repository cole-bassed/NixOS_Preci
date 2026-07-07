{
  lix,
  path,
  mkArgs,
  ...
}: let
  inherit (lix.attrsets) genAttrs hasAttrByPath optionalAttrs recursiveUpdate setAttrByPath;
  inherit (lix.modules) mkMerge;
  inherit (lix.options) mkEnableOption;
  inherit (lix.lists) elem;
  inherit (lix.types) isList isString;
  mkOptions = let
    defaults = {
      # parent = "undefined";
    };
  in
    overrides: {
    };
  mk = args: mkArgs ({inherit path;} // args);
  mkTarget.config = {
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
    inherit (mk {inherit config options pkgs;}) initiated evaluated;
    enabled = (config.${initiated.top}.interface.frontend.selected or null) == initiated.name;
  in {
    inherit (evaluated) options;
    config = mkMerge [
      evaluated.config
      (mkTarget.config {
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
    inherit (mod) initiated evaluated cfgOr;
    inherit (initiated) configs opt cfg name;
    enabled = cfg.enable or (cfg.isRequired or false);
    # hasNiri = (mkConfig {target = "domain";}).backends.niri.enable or false;
    hasNiri = configs.domain.backends.niri.enable or false;
  in {
    options =
      recursiveUpdate
      evaluated.options
      (opt ((mkOptions (genAttrs [] cfgOr))
        // {
          isRequired =
            mkEnableOption "Whether this ${name} is selected by the host or user"
            // {
              default = let
                target = configs.parent.selected;
              in
                if isList target
                then elem name target
                else if isString target
                then target == name
                else false;
            };
          needsNiri =
            mkEnableOption "Whether this ${name} is selected by the host or user"
            // {
              default = let
                target = configs.parent.selected;
              in
                if isList target
                then elem name target
                else if isString target
                then target == name
                else false;
            };
        }));
    config = mkMerge [
      evaluated.config
      (mkTarget.config {
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
# {
#   lix,
#   path,
#   mkArgs,
#   ...
# }: let
#   inherit (lix.attrsets) genAttrs hasAttrByPath optionalAttrs recursiveUpdate setAttrByPath;
#   inherit (lix.modules) mkMerge;
#   inherit (lix.options) mkEnableOption mkModuleArgs';
#   inherit (lix.lists) elem;
#   inherit (lix.types) isList isString;
#   mk = args: mkModuleArgs' ({inherit path;} // args);
#   mkOptions = let
#     defaults = {
#       # parent = "undefined";
#     };
#   in
#     overrides: {
#     };
#   mkTarget.config = {
#     target,
#     options,
#     enabled,
#   }: let
#     hasSub = key: hasAttrByPath (target ++ [key]) options;
#     cfg = optionalAttrs (hasSub "enable") {enable = enabled;};
#   in
#     optionalAttrs (cfg != {}) (setAttrByPath target cfg);
# in {
#   core = {
#     config,
#     options,
#     pkgs,
#     ...
#   }: let
#     inherit (mk {inherit config options pkgs;}) get;
#     # Clean lookup using the unified naming convention
#     enabled = (config.${get.config.top}.interface.frontend.selected or null) == get.name;
#   in {
#     options = get.options;
#     config = mkMerge [
#       get.config
#       (mkTarget.config {
#         inherit options enabled;
#         target = ["programs" "dms-shell"];
#       })
#     ];
#   };
#   home = {
#     config,
#     options,
#     pkgs,
#     ...
#   }: let
#     scope = "home";
#     mod = mk {inherit config options pkgs scope;};
#     inherit (mod) get set;
#     enabled = get.config.main.enable or (get.config.main.isRequired or false);
#     hasNiri = get.config.domain.backends.niri.enable or false;
#   in {
#     options =
#       recursiveUpdate
#       get.options
#       (set.options.module ((mkOptions (genAttrs [] (target: get.config.${target})))
#         // {
#           isRequired =
#             mkEnableOption "Whether this ${get.name} is selected by the host or user"
#             // {
#               default = let
#                 target = get.config.parent.selected;
#               in
#                 if isList target
#                 then elem get.name target
#                 else if isString target
#                 then target == get.name
#                 else false;
#             };
#           needsNiri =
#             mkEnableOption "Whether this ${get.name} is selected by the host or user"
#             // {
#               default = let
#                 target = get.config.parent.selected;
#               in
#                 if isList target
#                 then elem get.name target
#                 else if isString target
#                 then target == get.name
#                 else false;
#             };
#         }));
#     config = mkMerge [
#       get.config
#       (mkTarget.config {
#         inherit options enabled;
#         target = ["programs" "dank-material-shell"];
#       })
#       {
#         programs.dank-material-shell.niri = {
#           enableKeybinds = enabled && hasNiri;
#           enableSpawn = enabled && hasNiri;
#         };
#       }
#     ];
#   };
# }
