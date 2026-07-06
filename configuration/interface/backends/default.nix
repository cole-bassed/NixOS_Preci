{
  lix,
  top,
  host,
  path,
  registry,
  registryOf,
  selectionOf,
  ...
} @ args: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) attrValues hasAttr foldMerge mapAttrs optionalAttrs;
  inherit (lix.lists) init last;
  inherit (lix.modules) mkDefault mkIf mkMerge mkModules;
  inherit (lix.options) mkModuleArgs mkEnable mkEnableOption mkOption;
  inherit (lix.types) anything attrsOf submodule str nullOr package;

  cfgOf = spec: registryOf {inherit top registry spec;};
  selection = spec: selectionOf {inherit top registry spec;};
  path' = path;
  materialize = selected:
    mapAttrs
    (_: overrides: {enable = true;} // overrides)
    (foldMerge selected);

  required = let
    main = [(selection host)];
  in {
    core = materialize (
      main ++ (map selection (attrValues (getInteractiveUsers host)))
    );
    home = user: materialize (main ++ [(selection user)]);
  };
  type = attrsOf (submodule {freeformType = anything;});

  mkMod = {
    config,
    options ? {},
    scope ? "core",
    pkgs,
    path ? path',
  }: let
    module = mkModuleArgs {inherit top config path scope pkgs;};
    parent = mkModuleArgs {
      inherit config top scope;
      path = init path;
    };
    inherit (module) bin prettyName name configs cfg opt;
    data = registry.${module.name} or {};
    isWayland = data.protocol or null == "wayland";

    fields =
      {
        enable = mkEnable {
          inherit name scope;
          default =
            if scope == "home"
            then hasAttr name configs.parent
            else hasAttr name required.core;
        };
        package = mkOption {
          type = nullOr package;
          default = pkgs.${name} or null;
          description = "Package backing the ${prettyName} compositor component.";
        };
      }
      // optionalAttrs (scope == "core") {
        uwsm = mkOption {
          description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
          type = submodule {
            options = {
              enable =
                mkEnableOption "${prettyName} UWSM support."
                // {
                  default =
                    if hasAttr "uwsm" data
                    then data.uwsm
                    else isWayland && fields.enable.default;
                };
              name = mkOption {
                type = str;
                description = "Human-readable name shown by UWSM.";
                default = prettyName;
              };
              description = mkOption {
                type = str;
                description = "Comment shown by UWSM.";
                default = "${prettyName} compositor managed by UWSM";
              };
              binary = mkOption {
                type = str;
                description = "Absolute path to the compositor binary.";
                default = bin.path;
              };
            };
          };
        };
      };
  in {
    args = {
      inherit module parent;
      registry = data;
    };

    opts = {
      module = module.opt fields;
      parent = parent.opt {
        ${last path} = mkOption {
          inherit type;
          default = required.core;
          description = "Required compositor backends as a component-native attrset keyed by backend name.";
        };
      };
    };

    cfgs = {
      module =
        if scope == "home"
        then opt {enable = mkDefault fields.enable.default;}
        else
          mkMerge [
            (mkIf (cfg.enable or false) {
              programs.${name}.enable = cfg.enable;
            })
            (mkIf (
                (cfg.enable or false)
                && hasAttr "programs" options
                && hasAttr name options.programs
                && hasAttr "package" options.programs.${name}
              ) {
                programs.${name}.package = cfg.package;
              })
            (mkIf ((cfg.enable or false) && isWayland && (cfg.uwsm.enable or false)) {
              programs.uwsm = {
                enable = true;
                waylandCompositors.${name} = with cfg.uwsm; {
                  prettyName = name;
                  comment = description;
                  binPath = binary;
                };
              };
            })
          ];
    };
  };

  inner = mkModules (args
    // {
      base = ./.;
      excludes = [];
      declareRegistry = false;
      childPath = path;
      extraArgs = {
        inherit cfgOf;
        mkArgs = {
          config,
          options ? {},
          path,
          pkgs ? {},
          scope ? "core",
        }: let
          mod = mkMod {inherit config options path pkgs scope;};
          inherit (mod) args opts cfgs;
        in
          args.module
          // {
            initiated = args.module;
            evaluated = {
              options = opts.module;
              config = cfgs.module;
            };
          };
        mkEnable = {
          config,
          pkgs ? {},
          scope,
          path ? path',
          ...
        }: let
          mod = mkMod {inherit config pkgs scope path;};
        in {inherit (mod.fields) enable package;};
      };
      # extraArgs = {
      #   inherit cfgOf;
      #   mkArgs = {
      #     config,
      #     options ? {},
      #     path,
      #     pkgs ? {},
      #     scope ? "core",
      #   }: let
      #     moduleArgs = mkModuleArgs {inherit top config path scope pkgs;};
      #     inherit (moduleArgs) bin prettyName opt name cfg;
      #     meta = registry.${name} or {};
      #     isWayland = meta.protocol or null == "wayland";
      #     enable = mkEnable {
      #       inherit name scope;
      #       default =
      #         if scope == "home"
      #         then hasAttr name moduleArgs.configs.parent
      #         else hasAttr name required;
      #     };
      #   in
      #     moduleArgs
      #     // {
      #       initiated = moduleArgs;
      #       evaluated =
      #         if scope == "core"
      #         then {
      #           options = opt {
      #             inherit enable;
      #             package = mkOption {
      #               type = anything;
      #               default = pkgs.${name} or null;
      #               description = "Package backing the ${prettyName} compositor component.";
      #             };
      #             uwsm = mkOption {
      #               description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
      #               type = submodule {
      #                 options = {
      #                   enable =
      #                     mkEnableOption "${prettyName} UWSM support."
      #                     // {
      #                       default =
      #                         if hasAttr "uwsm" meta
      #                         then meta.uwsm
      #                         else isWayland && enable.default;
      #                     };
      #                   name = mkOption {
      #                     type = str;
      #                     description = "Human-readable name shown by UWSM.";
      #                     default = prettyName;
      #                   };
      #                   description = mkOption {
      #                     type = str;
      #                     description = "Comment shown by UWSM.";
      #                     default = "${prettyName} compositor managed by UWSM";
      #                   };
      #                   binary = mkOption {
      #                     type = str;
      #                     description = "Absolute path to the compositor binary.";
      #                     default = bin.path;
      #                   };
      #                 };
      #               };
      #             };
      #           };
      #           config = mkMerge [
      #             (mkIf (cfg.enable or false) {
      #               programs.${name}.enable = cfg.enable;
      #             })
      #             (mkIf (
      #                 (cfg.enable or false)
      #                 && hasAttr "programs" options
      #                 && hasAttr name options.programs
      #                 && hasAttr "package" options.programs.${name}
      #               ) {
      #                 programs.${name}.package = cfg.package;
      #               })
      #             (mkIf ((cfg.enable or false) && isWayland && (cfg.uwsm.enable or false)) {
      #               programs.uwsm = {
      #                 enable = true;
      #                 waylandCompositors.${name} = with cfg.uwsm; {
      #                   prettyName = name;
      #                   comment = description;
      #                   binPath = binary;
      #                 };
      #               };
      #             })
      #           ];
      #         }
      #         else {
      #           options = opt {
      #             inherit enable;
      #             package = mkOption {
      #               type = anything;
      #               default = pkgs.${name} or null;
      #               description = "Package backing the ${prettyName} compositor component.";
      #             };
      #           };
      #           config = opt {enable = mkDefault enable.default;};
      #         };
      #     };
      #   mkEnable = {
      #     name ? null,
      #     prettyName ? name,
      #     config,
      #     pkgs ? {},
      #     scope,
      #     path ? [],
      #     ...
      #   }: let
      #     moduleArgs = mkModuleArgs {inherit top config scope path pkgs;};
      #     default =
      #       if scope == "home"
      #       then hasAttr name moduleArgs.configs.parent
      #       else hasAttr name required;
      #   in {
      #     enable = mkEnable {inherit name scope default;};
      #     package = mkOption {
      #       type = nullOr package;
      #       default = pkgs.${name} or null;
      #       description = "Package backing the ${prettyName} compositor component.";
      #     };
      #   };
      # };
    });
in {
  core = {
    config,
    pkgs,
    ...
  }: let
    mod = mkMod {inherit config pkgs;};
  in {
    imports = inner.imports or [];
    options = mod.opts.parent;
    config.${top}.interface.backends = mkDefault required.core;
  };

  home = {user ? {}, ...}: {
    imports = inner.home-manager.sharedModules or [];
    options = {};
    config.${top}.interface.backends = mkDefault (required.home user);
  };
}
