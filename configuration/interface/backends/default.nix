# {
#   lix,
#   top,
#   host,
#   path,
#   registry,
#   registryOf,
#   resolve,
#   ...
# } @ args: let
#   inherit (lix.api) getInteractiveUsers;
#   inherit (lix.attrsets) attrNames attrValues listToAttrs;
#   inherit (lix.modules) mkModules;
#   inherit (lix.lists) concatMap elem head tail filter init map unique;
#   inherit (lix.options) mkModuleArgs mkEnable mkOption;
#   inherit (lix.strings) concatStringsSep;
#   inherit (lix.types) either attrsOf anything enum listOf;
#   cfgOf = spec: registryOf {inherit top registry spec;};
#   type =
#     either
#     (listOf (enum (attrNames registry)))
#     (attrsOf anything);
#   mkArgs' = config: scope:
#     mkModuleArgs {inherit config top scope path;};
# in let
#   inner = mkModules (args
#     // {
#       base = ./.;
#       declareRegistry = false;
#       childPath = init path;
#       extraArgs = {
#         inherit cfgOf;
#         mkArgs = {
#           config,
#           path,
#           scope ? "core",
#           extra ? {},
#         }:
#           mkModuleArgs ({inherit config top path scope;} // extra);
#         mkEnable = {
#           name,
#           prettyName ? name,
#           config,
#           scope,
#         }: let
#           required = let
#             path' =
#               if scope == "core"
#               then [(head path) "required"] ++ (tail path)
#               else path;
#             parent = mkModuleArgs {
#               inherit config top scope;
#               path = path';
#             };
#           in
#             parent.cfg.${parent.leaf} or [];
#           # required = let
#           #   path' =
#           #     if scope == "core"
#           #     then [(head path) "required"] ++ (tail path)
#           #     else path;
#           #   parent = mkModuleArgs {
#           #     inherit config top scope;
#           #     path = path';
#           #   };
#           # in
#           #   parent.cfg.${parent.leaf} or [];
#           # required = let
#           #   path' =
#           #     if scope == "core"
#           #     then [(head path) "required"] ++ (tail path)
#           #     else path;
#           # in
#           #   concatStringsSep "." ([config top] ++ path');
#           # required =
#           #   if scope == "core"
#           #   then config.${top}.interface.required.backends or [] # TODO: This should use path, but with "required" after head of the list ["interface" "required" "backends"]
#           #   else config.${top}.interface.backends or []; # TODO: This should use path ["interface" "backends"]
#           backend = registry.${name} or {};
#         in {
#           enable =
#             (mkEnable {
#               description = "${prettyName} compositor";
#               default = elem name required;
#               inherit name scope;
#             }).default;
#           withUWSM =
#             (mkEnable {
#               description = "launching ${prettyName} through UWSM";
#               default = backend.uwsm or false;
#             }).default;
#           #TODO: Add the uwsm option to the actual final uwsm config.
#         };
#       };
#     });
# in {
#   core = {config, ...}: let
#     parent = mkModuleArgs {
#       inherit config top;
#       path = ["interface"];
#       scope = "core";
#     };
#   in {
#     imports = inner.imports or [];
#     options = parent.opt {
#       required.backends = mkOption {
#         inherit type;
#         default = unique (
#           (cfgOf host) ++ (concatMap cfgOf (attrValues (getInteractiveUsers host)))
#         );
#         description = "Required compositor backends. Accepts a list of names or an attrset with per-backend overrides.";
#       };
#       path = mkOption {
#         # type = listOf str;
#         default = path;
#         description = "Path to search for backends.";
#       };
#     };
#     config.programs.uwsm.waylandCompositors = listToAttrs (
#       map
#       (
#         env: {
#           name = env.name;
#           value = {
#             prettyName = env.name;
#             comment = "${env.name} compositor managed by UWSM";
#             binPath = "/run/current-system/sw/bin/${env.session}";
#           };
#         }
#       )
#       (
#         filter (env: env.uwsm or false)
#         (resolve {
#           inherit registry;
#           spec = host;
#         })
#       )
#     );
#   };
#   home = {
#     config,
#     user ? {},
#     ...
#   }: let
#     parent = mkModuleArgs {
#       inherit config top;
#       path = ["interface"];
#       scope = "home";
#     };
#   in {
#     imports = inner.home-manager.sharedModules or [];
#     options = parent.opt {
#       backends = mkOption {
#         inherit type;
#         default = unique (cfgOf host ++ cfgOf user);
#         description = "Enabled compositor backends for this user.";
#       };
#     };
#   };
# }
{
  lix,
  top,
  host,
  path,
  registry,
  registryOf,
  resolve,
  ...
} @ args: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) attrNames attrValues listToAttrs;
  inherit (lix.lists) concatMap elem filter head init map tail unique;
  inherit (lix.modules) mkModules;
  inherit (lix.options) mkModuleArgs mkEnable mkOption;
  inherit (lix.types) either attrsOf anything enum listOf nullOr submodule str;

  cfgOf = spec: registryOf {inherit top registry spec;};

  type =
    either
    (listOf (enum (attrNames registry)))
    (attrsOf anything);

  mkArgs' = config: scope:
    mkModuleArgs {inherit config top scope path;};

  # UWSM entry type — can be null (disabled) or a submodule with the actual fields
  uwsmType = nullOr (submodule {
    options = {
      name = mkOption {
        type = str;
        description = "Human-readable name shown by UWSM.";
      };
      description = mkOption {
        type = str;
        description = "Comment shown by UWSM.";
      };
      path = mkOption {
        type = str;
        description = "Absolute path to the compositor binary.";
      };
    };
  });
in let
  inner = mkModules (args
    // {
      base = ./.;
      declareRegistry = false;
      childPath = init path;
      extraArgs = {
        inherit cfgOf;

        mkArgs = {
          config,
          path,
          scope ? "core",
          extra ? {},
        }:
          mkModuleArgs ({inherit config top path scope;} // extra);

        mkEnable = {
          name,
          prettyName ? name,
          config,
          scope,
        }: let
          required = let
            mk = attrs: path:
              if path == []
              then attrs
              else if attrs ? ${head path}
              then mk (attrs.${head path}) (tail path)
              else [];
          in
            mk config (
              [top]
              ++ (
                if scope == "core"
                then [(head path) "required"] ++ (tail path)
                else path
              )
            );

          backend =
            (registry.${name} or {})
            // {
              inherit name prettyName;
              session = "  ";
            };
        in {
          enable =
            (mkEnable {
              description = "${prettyName} compositor";
              default = elem name required;
              inherit name scope;
            }).default;

          uwsm = mkOption {
            type = uwsmType;
            default =
              if backend ? uwsm
              then let
                pretty = backend.uwsm.name or prettyName;
                # session = backend.session or
              in {
                prettyName = name;
                comment = backend.uwsm.description or "${pretty} compositor managed by UWSM";
                path = backend.uwsm.path or "/run/current-system/sw/bin/${backend.session or backend.prpretty}";
              }
              else null;
            description = "UWSM configuration for ${prettyName}. Set to `null` to disable UWSM integration.";
          };
        };
      };
    });
in {
  core = {config, ...}: let
    parent = mkModuleArgs {
      inherit config top;
      path = ["interface"];
      scope = "core";
    };
  in {
    imports = inner.imports or [];
    options = parent.opt {
      required.backends = mkOption {
        inherit type;
        default = unique (
          (cfgOf host) ++ (concatMap cfgOf (attrValues (getInteractiveUsers host)))
        );
        description = "Required compositor backends. Accepts a list of names or an attrset with per-backend overrides.";
      };
      path = mkOption {
        # type = listOf str;
        default = path;
        description = "Path to search for backends.";
      };
    };
    config.programs.uwsm.waylandCompositors = let
      envs = resolve {
        inherit registry;
        spec = host;
      };
      uwsmEnvs =
        filter (
          env: let
            backendCfg = config.${top}.interface.${env.name} or {};
          in
            (backendCfg.enable or false)
            && (backendCfg.uwsm or null) != null
        )
        envs;
    in
      listToAttrs (
        map (
          env: let
            cfg = config.${top}.interface.${env.name}.uwsm;
          in {
            name = cfg.name;
            value = {
              inherit (cfg) prettyName;
              comment = cfg.description;
              binPath = cfg.path;
            };
          }
        )
        uwsmEnvs
      );
  };

  home = {
    config,
    user ? {},
    ...
  }: let
    parent = mkModuleArgs {
      inherit config top;
      path = ["interface"];
      scope = "home";
    };
  in {
    imports = inner.home-manager.sharedModules or [];
    options = parent.opt {
      backends = mkOption {
        inherit type;
        default = unique (cfgOf host ++ cfgOf user);
        description = "Enabled compositor backends for this user.";
      };
    };
  };
}
