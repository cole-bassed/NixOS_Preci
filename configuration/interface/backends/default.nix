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
  inherit (lix.modules) mkModules mkIf;
  inherit (lix.lists) concatMap elem filter init map unique;
  inherit (lix.options) mkModuleArgs mkEnable mkOption;
  inherit (lix.types) either attrsOf anything enum listOf;

  cfgOf = spec: registryOf {inherit top registry spec;};

  type =
    either
    (listOf (enum (attrNames registry)))
    (attrsOf anything);

  mkArgs' = config: scope:
    mkModuleArgs {inherit config top scope path;};
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
          parent = mkArgs' config scope;
          backend = registry.${name} or {};
        in {
          enable =
            (mkEnable {
              description = "${prettyName} compositor";
              default = elem name (parent.cfg.${parent.leaf} or []);
              inherit name scope;
            }).default;

          withUWSM =
            (mkEnable {
              description = "launching ${prettyName} through UWSM";
              default = backend.uwsm or false;
            }).default;
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
    };
    config.programs.uwsm.waylandCompositors = listToAttrs (
      map
      (
        env: {
          name = env.name;
          value = {
            prettyName = env.name;
            comment = "${env.name} compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/${env.session}";
          };
        }
      )
      (
        filter (env: env.uwsm or false)
        (resolve {
          inherit registry;
          spec = host;
        })
      )
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
