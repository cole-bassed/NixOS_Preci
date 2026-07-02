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
  inherit (lix.options) mkCfg mkModuleArgs mkEnable mkOption;
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
      ++ (
        concatMap
        backendsOf
        (attrValues (getInteractiveUsers host))
      )
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

        # mkEnable = {
        #   name,
        #   prettyName ? name,
        #   config,
        #   scope,
        # }:
        #   mkEnable {
        #     description = "${prettyName} compositor";
        #     default = elem name config.${top}.interface.backends; # TODO: Why are we hadcoding here 'interface.backend'. Should this not be smarted based on path?
        #     inherit name scope;
        #   };
        mkEnable = {
          name,
          prettyName ? name,
          config,
          scope,
        }: let
          # parentArgs is the mkArgsHelper output for the current folder level
          parentArgs = mkArgsHelper config scope;
        in
          mkEnable {
            description = "${prettyName} compositor";
            # Dynamically look up the option name using the folder's leaf name!
            default = elem name (parentArgs.cfg.${parentArgs.leaf} or []);
            inherit name scope;
          };
      };
    });
in {
  core = {config, ...}: let
    inherit ((mkArgsHelper config "core")) opt;

    uwsm = let
      backends = filter (env: env.uwsm or false) (resolveEnvironments {inherit registry host;});
      compositors = listToAttrs (
        map (env: {
          name = env.name;
          value = {
            prettyName = env.name;
            comment = "${env.name} compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/${env.session}";
          };
        })
        backends
      );
    in {inherit backends compositors;};
  in {
    imports = inner.imports or [];
    options = opt (opts spec.core);
    config = mkIf (uwsm.compositors != {}) {
      programs.uwsm.waylandCompositors = listToAttrs (map (env: {
          name = env.name;
          value = {
            prettyName = env.name;
            comment = "${env.name} compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/${env.session}";
          };
        })
        uwsm.backends);
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
