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

  type =
    either
    (listOf (enum (attrNames registry)))
    (attrsOf anything);

  mkArgs' = config: scope:
    mkModuleArgs {inherit config top scope path;};

  # `backends` is a container directory, not a namespace: its own
  # option (the enable list/overrides) lives at dots.interface.backends,
  # but the per-backend submodules (hyprland, niri, mango) must register
  # as siblings under dots.interface.<name>, not nested inside it.
  parentPath = init path;
in let
  inner = mkModules (args
    // {
      base = ./.;
      path = parentPath;
      extraArgs = {
        inherit registryOf;

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
    # Use path=["interface"] so we define dots.interface.backends
    parent = mkModuleArgs {
      inherit config top;
      path = ["interface"];
      scope = "core";
    };

    uwsm = let
      backends =
        filter (env: env.uwsm or false)
        (resolve {
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
        inherit type;
        default = unique (
          (registryOf host)
          ++ (concatMap registryOf (attrValues (getInteractiveUsers host)))
        );
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
  in {
    imports = inner.home-manager.sharedModules or [];
    options = parent.opt {
      backends = mkOption {
        inherit type;
        default = unique (registryOf host ++ registryOf user);
        description = "Enabled compositor backends for this user.";
      };
    };
  };
}
