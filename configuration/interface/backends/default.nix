{
  lix,
  top,
  host,
  path,
  registry,
  resolveBackends,
  ...
} @ args: let
  inherit (lix.api) getInteractiveUsers;
  inherit (lix.attrsets) attrNames attrValues listToAttrs;
  inherit (lix.modules) mkModules mkIf;
  inherit (lix.lists) concatMap elem filter map unique;
  inherit (lix.options) mkModuleArgs mkEnable mkOption;
  inherit (lix.types) either attrsOf anything enum listOf;

  cfgOf = spec:
    map (env: env.name) (resolveBackends {
      inherit registry;
      spec = spec;
    });

  allEnvs = attrNames registry.environments;

  # Collect backends from host + all interactive users
  activeBackends = unique (
    (cfgOf host)
    ++ (concatMap cfgOf (attrValues (getInteractiveUsers host)))
  );

  # Type: accept list of strings OR attrset of anything
  backendType = either (listOf (enum allEnvs)) (attrsOf anything);

  # For submodules: path should be ["interface" "backends"] so they create
  # dots.interface.backends.hyprland, etc.
  submodulePath = path ++ ["backends"];

  mkArgs' = config: scope:
    mkModuleArgs {
      inherit config top scope;
      path = submodulePath;
    };
in let
  inner = mkModules (args
    // {
      base = ./.;
      path = submodulePath;
      extraArgs = {
        inherit cfgOf;

        mkArgs = {
          config,
          path ? submodulePath,
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
    # Use path=["interface"] so we define dots.interface.backends
    parent = mkModuleArgs {
      inherit config top;
      path = ["interface"];
      scope = "core";
    };

    uwsm = let
      backends =
        filter (env: env.uwsm or false)
        (resolveBackends {
          inherit registry;
          spec = host;
        });
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
    options = parent.opt {
      backends = mkOption {
        type = backendType;
        default = activeBackends;
        description = "Enabled compositor backends. Accepts a list of names or an attrset with per-backend overrides.";
      };
    };
    config = mkIf (uwsm.compositors != {}) {
      programs.uwsm.waylandCompositors = uwsm.compositors;
    };
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
    userBackends = unique (cfgOf host ++ cfgOf user);
  in {
    imports = inner.home-manager.sharedModules or [];
    options = parent.opt {
      backends = mkOption {
        type = backendType;
        default = userBackends;
        description = "Enabled compositor backends for this user.";
      };
    };
  };
}
