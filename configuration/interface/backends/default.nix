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
  inherit (lix.lists) concatMap elem filter head init last map tail unique;
  inherit (lix.modules) mkModules;
  inherit (lix.options) mkModuleArgs mkEnable mkOption;
  inherit (lix.types) either attrsOf anything enum listOf nullOr submodule str;

  cfgOf = spec: registryOf {inherit top registry spec;};

  type =
    either
    (listOf (enum (attrNames registry)))
    (attrsOf anything);

  mkArgs' = config: scope: mkModuleArgs {inherit config top scope path;};
in let
  inner = mkModules (args
    // {
      base = ./.;
      declareRegistry = false;
      childPath = init path;
      extraArgs = {
        inherit cfgOf;

        name = last path;

        mkArgs = {
          config,
          path,
          scope ? "core",
          extra ? {},
        }:
          mkModuleArgs ({inherit config top path scope;} // extra);

        mkEnable = {
          # name,
          # prettyName ? name,
          # session ? name,
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

          entry = let
            spec = registry.${name} or {};
          in
            spec
            // {
              inherit name;
              prettyName = spec.prettyName or prettyName;
              session = spec.session or session;
            };
        in {
          enable =
            (mkEnable {
              description = "${prettyName} compositor";
              default = elem name required;
              inherit name scope;
            }).default;

          uwsm = mkOption {
            type = nullOr (submodule {
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
