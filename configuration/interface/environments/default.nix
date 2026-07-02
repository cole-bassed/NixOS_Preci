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
  inherit (lix.types) either attrsOf anything isList enum listOf;

  cfgOf = host:
    map
    (env: env.name)
    (resolveEnvironments {inherit host registry;});

  spec = {
    all = attrNames registry.environments;
    core = unique (
      (cfgOf host)
      ++ (
        concatMap
        cfgOf
        (attrValues (getInteractiveUsers host))
      )
    );
    home = user: unique (cfgOf host ++ cfgOf user);
  };

  # Logic to normalize input into a single attrset: { hyprland = {}; niri = {}; }
  normalize = args:
    if isList args
    then
      listToAttrs (
        map (name: {
          inherit name;
          value = {};
        })
        args
      )
    else args;

  opts = preset: let
    description = "List of environments or attribute set of backend configurations.";
    type = either (listOf (enum spec.all)) (attrsOf anything);
    default = normalize preset;
    apply = normalize;
  in
    mkOption {inherit description type default apply;};

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
        filter
        (env: env.uwsm or false)
        (resolveEnvironments {inherit registry host;});
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
