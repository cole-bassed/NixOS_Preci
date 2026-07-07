{
  lix,
  top,
  host,
  path,
  registry,
  selection,
  ...
} @ args: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) attrByPath attrValues hasAttr hasAttrByPath foldMerge mapAttrs optionalAttrs setAttrByPath;
  inherit (lix.lists) findFirst init;
  inherit (lix.modules) mkDefault mkIf mkMerge mkModules;
  inherit (lix.options) mkModuleArgs mkEnable mkEnableOption mkOption;
  inherit (lix.types) submodule str nullOr package;

  path' = path;
  materialize = selected:
    mapAttrs
    (_: extra: {enable = true;} // extra)
    (foldMerge selected);

  required = let
    main = [(selection host)];
  in {
    core =
      materialize
      (main ++ (map selection (attrValues (getInteractiveUsers host))));
    home = user: materialize (main ++ [(selection user)]);
  };

  mkMod = {
    config,
    options ? {},
    scope ? "core",
    pkgs,
    path ? path',
  }: let
    users = getInteractiveUsers host;
    module = mkModuleArgs {inherit top config path scope pkgs users options;};
    parent = mkModuleArgs {
      inherit config top scope;
      path = init path;
    };
    bin = module.set.bin {};
    inherit (module.get) prettyName name user;
    cfg = module.get.config.module;
    opt = module.set.options.module;
    data = registry.${name} or {};
    isWayland = data.protocol or null == "wayland";

    fields =
      {
        enable = mkEnable {
          inherit name scope;
          default =
            if scope == "home"
            then hasAttr name (required.home user)
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
    inherit fields;
    args = {
      inherit module parent;
      registry = data;
    };
    options = module.set.options.module fields;
    config =
      if scope == "home"
      then let
        target = findFirst (path: hasAttrByPath path options) null [
          ["wayland" "windowManager" name]
          ["programs" name]
        ];
        hasSub = key: target != null && hasAttrByPath (target ++ [key]) options;
        homeCfg =
          optionalAttrs (hasSub "enable") {enable = mkDefault fields.enable.default;}
          // optionalAttrs (hasSub "package") {inherit (cfg) package;};
      in
        mkMerge [
          (opt {enable = mkDefault fields.enable.default;})
          (optionalAttrs (target != null && homeCfg != {}) (setAttrByPath target homeCfg))
        ]
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

  inner = mkModules (args
    // {
      base = ./.;
      excludes = [];
      declareRegistry = false;
      childPath = path;
      extraArgs = {
        # cfgOf = spec: registryOf {inherit top registry spec;};

        mkArgs = {
          config,
          options ? {},
          path,
          pkgs ? {},
          scope ? "core",
          osConfig ? config,
          defaults ? {},
        }: let
          mod = mkMod {inherit config options path pkgs scope;};
          initiated = mod.args.module;
          evaluated = {inherit (mod) options config;};
          cfgOr = key:
            attrByPath
            ([top] ++ path ++ [key]) (defaults.${key} or null)
            osConfig;
        in
          initiated
          // {
            inherit initiated evaluated cfgOr;
            inherit (initiated) get set;
          };

        mkEnable = {
          config,
          pkgs ? {},
          scope,
          path ? path',
          ...
        }:
          (mkMod {inherit config pkgs scope path;}).fields;
      };
    });
in {
  core.imports = inner.imports or [];
  home.imports = inner.home-manager.sharedModules or [];
}
