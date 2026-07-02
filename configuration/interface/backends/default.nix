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
  inherit (lix.lists) concatMap elem map unique filter;
  inherit (lix.options) mkModuleArgs mkEnable mkOption;
  inherit (lix.types) enum listOf;

  backendsOf = spec:
    map (e: e.name) (resolveEnvironments {
      host = spec;
      inherit registry;
    });

  spec = {
    all = attrNames registry.environments;
    core = unique (
      (backendsOf host)
      ++ (concatMap backendsOf (attrValues (getInteractiveUsers host)))
    );
    home = user: unique (backendsOf host ++ backendsOf user);
  };

  opts = preset: {
    backends = mkOption {
      type = listOf (enum spec.all);
      default = preset;
      description = "Enabled window managers and desktop environments, resolved from interface.environments.";
    };
  };

  mkArgsHelper = config: scope: mkModuleArgs {inherit config top path scope;};
in let
  inner = mkModules (args
    // {
      base = ./.;
      path = path;
      extraArgs = {
        backendsOf = backendsOf;

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
        }:
          mkEnable {
            description = "${prettyName} compositor";
            default = elem name config.${top}.interface.backend.backends;
            inherit name scope;
          };
      };
    });
in {
  core = {config, ...}: let
    inherit ((mkArgsHelper config "core")) opt;

    # Resolve full registry objects for this active host environment context
    activeEnvs = resolveEnvironments {inherit registry host;};

    # Extract only backends declaring `uwsm = true;` inside the central registry
    uwsmBackends = filter (env: env.uwsm or false) activeEnvs;

    # Dynamically build the configuration payload inline
    uwsmCompositors = listToAttrs (map (env: {
        name = env.name;
        value = {
          prettyName = env.name;
          comment = "${env.name} compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/${env.session}";
        };
      })
      uwsmBackends);
  in {
    imports = inner.imports or [];
    options = opt (opts spec.core);

    # Expose dynamically configured compositors if any are active
    config = mkIf (uwsmCompositors != {}) {
      programs.uwsm.waylandCompositors = uwsmCompositors;
    };
  };

  home = {
    config,
    user ? {},
    ...
  }: let
    inherit ((mkArgsHelper config "home")) opt;
  in {
    imports = inner.home-manager.sharedModules or [];
    options = opt (opts (spec.home user));
  };
}
