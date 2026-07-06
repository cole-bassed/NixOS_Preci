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
  inherit (lix.attrsets) attrValues hasAttr foldMerge mapAttrs recursiveUpdate;
  inherit (lix.lists) foldl' init last;
  inherit (lix.modules) mkDefault mkIf mkMerge mkModules;
  inherit (lix.options) mkModuleArgs mkEnable mkEnableOption mkOption;
  inherit (lix.types) anything attrsOf submodule str;

  cfgOf = spec: registryOf {inherit top registry spec;};
  selection = spec: selectionOf {inherit top registry spec;};
  materialize = selected:
    mapAttrs (_: overrides: {enable = true;} // overrides) selected;

  required = materialize (foldMerge (
    [(selection host)]
    ++ (map selection (attrValues (getInteractiveUsers host)))
  ));

  type = attrsOf (submodule {freeformType = anything;});

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
          moduleArgs = mkModuleArgs {inherit top config path scope pkgs;};
          # options' = options;
          inherit (moduleArgs) bin prettyName opt name cfg;

          enableOption = mkEnable {
            inherit name scope;
            default =
              if scope == "home"
              then hasAttr name moduleArgs.configs.parent
              else hasAttr name required;
          };
        in
          moduleArgs
          // {
            initiated = moduleArgs;
            evaluated =
              if scope == "core"
              then {
                options = opt {
                  enable = enableOption;
                  package = mkOption {
                    type = anything;
                    default = pkgs.${name} or null;
                    description = "Package backing the ${prettyName} compositor component.";
                  };
                  uwsm = mkOption {
                    description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
                    type = submodule {
                      options = {
                        enable =
                          mkEnableOption "${prettyName} UWSM support."
                          // {default = registry.${name}.uwsm or false;};
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
                config = mkMerge [
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
                  (mkIf (cfg.uwsm.enable or false) {
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
              }
              else {
                options = opt {
                  enable = enableOption;
                  package = mkOption {
                    type = anything;
                    default = pkgs.${name} or null;
                    description = "Package backing the ${prettyName} compositor component.";
                  };
                };
                config = opt {enable = mkDefault enableOption.default;};
              };
          };
        mkEnable = {
          name ? null,
          prettyName ? name,
          config,
          pkgs ? {},
          scope,
          path ? [],
          ...
        }: let
          moduleArgs = mkModuleArgs {inherit top config scope path pkgs;};
          default =
            if scope == "home"
            then hasAttr name moduleArgs.configs.parent
            else hasAttr name required;
        in {
          enable = mkEnable {inherit name scope default;};
          package = mkOption {
            type = anything;
            default = pkgs.${name} or null;
            description = "Package backing the ${prettyName} compositor component.";
          };
        };
      };
    });
in {
  core = {config, ...}: let
    scope = "core";
    mk = path: mkModuleArgs {inherit config top path scope;};
    parent = mk (init path);
  in {
    imports = inner.imports or [];
    options = parent.opt {
      required.${last path} = mkOption {
        inherit type;
        default = required;
        description = "Required compositor backends as a component-native attrset keyed by backend name.";
      };
    };
    config.${top}.interface.backends = mkDefault required;
  };

  home = {user ? {}, ...}: let
    selected = materialize (foldMerge [(selection host) (selection user)]);
  in {
    imports = inner.home-manager.sharedModules or [];
    options = {};
    config.${top}.interface.backends = mkDefault selected;
  };
}
