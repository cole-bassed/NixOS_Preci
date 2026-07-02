{
  lix,
  top,
  host,
  path,
  registry,
  resolveEnvironments,
  ...
} @ args: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) attrNames attrValues listToAttrs;
  inherit (lix.modules) mkModules mkIf;
  inherit (lix.lists) concatMap elem filter map unique;
  inherit (lix.options) mkModuleArgs mkEnable mkOption;
  inherit (lix.types) either attrsOf anything enum isList listOf;

  cfgOf = spec:
    map (env: env.name) (resolveEnvironments {
      inherit registry;
      host = spec;
    });

  allEnvs = attrNames registry.environments;

  # Collect backends from host + all interactive users
  spec = {
    all = allEnvs;
    core = unique (
      (cfgOf host)
      ++ (concatMap cfgOf (attrValues (getInteractiveUsers host)))
    );
    home = user: unique (cfgOf host ++ cfgOf user);
  };

  opts = preset: {
    backends = mkOption {
      type = either (listOf (enum allEnvs)) (attrsOf anything);
      default =
        if isList preset
        then preset
        else {};
      description = "List of backend names or attrset of backend configurations.";
    };
  };

  mkArgs' = config: scope: mkModuleArgs {inherit config top path scope;};
in let
  inner = mkModules (args
    // {
      base = ./.;
      inherit path;
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
          env = registry.environments.${name} or {};
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
              default = env.uwsm or false;
            }).default;
        };
      };
    });
in {
  core = {config, ...}: let
    inherit ((mkArgs' config "core")) opt;

    uwsm = let
      backends =
        filter (env: env.uwsm or false)
        (resolveEnvironments {inherit registry host;});
      compositors = listToAttrs (map (env: {
          name = env.name;
          value = {
            prettyName = env.name;
            comment = "${env.name} compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/${env.session}";
          };
        })
        backends);
    in {inherit backends compositors;};
  in {
    imports = inner.imports or [];
    options = opt (opts spec.core);
    config = mkIf (uwsm.compositors != {}) {
      programs.uwsm.waylandCompositors = uwsm.compositors;
    };
  };

  home = {
    config,
    user ? {},
    ...
  }: let
    inherit ((mkArgs' config "home")) opt;
  in {
    imports = inner.home-manager.sharedModules or [];
    options = opt (opts (spec.home user));
  };
}
