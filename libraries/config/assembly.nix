{
  api,
  debug,
  attrsets,
  lists,
  external,
  types,
  paths,
  names,
  strings,
  defaults,
  systems,
  environment,
  ...
}: let
  exports = {
    scoped = {
      configurations = mkConfigurations;
      systems = mkConfigurations;
      flake = mkFlake;
      inherit mkConfigurations mkFlake;
    };
    global = {
      inherit mkFlake mkConfigurations;
    };
  };

  inherit (external.flake.modules) mkMods;
  inherit (attrsets) namesOf filterAttrs genAttrs mapAttrs mapAttrsToList mergeAttrsList optionalAttrs recursiveUpdate;
  inherit (debug) withContext expect;
  inherit (environment) mkSrc;
  inherit (lists) elem foldl' groupBy;
  inherit (types) isAttrs isBool isEnabled typeOf;
  inherit (api) hosts;
  inherit (strings) concat;
  inherit (systems) getClassification getBuilder;

  defaultHost = api.hosts.${defaults.host};

  mkPaths = base:
    mapAttrs (
      name: value:
        expect {
          type = "path";
          inherit value;
          name = "config.assembly.mkFlake.paths";
          context = "validating paths before import loop";
        }
    )
    (recursiveUpdate paths.store (base.paths.store or (base.paths or {})));

  mkFlake = arg: let
    _name = "config.assembly.mkFlake";
    exec = base: mods: let
      normalize = value:
        assert withContext {
          name = _name;
          assertion = isBool value || isAttrs value;
          message = "expected a bool or attrset, got ${typeOf value}";
          context = "normalising path spec in assemble";
        };
          optionalAttrs (isAttrs value) (removeAttrs value ["enable"]);

      resolved = {
        paths = mkPaths base;
      };

      enabled =
        filterAttrs (
          name: value:
            assert withContext {
              inherit name;
              assertion = resolved.paths ? ${name};
              message = "'${name}' is not a known path in paths.store";
              context = "resolving path for '${name}' in assemble";
            };
              (name != "configurations") && (isEnabled value)
        )
        mods;
    in
      mergeAttrsList (
        mapAttrsToList (
          name: args:
            import resolved.paths.${name} (base // {args = normalize args;})
        )
        enabled
      )
      // (
        let
          configurations = mods.configurations or false;
        in
          optionalAttrs (isEnabled configurations) (
            mkConfigurations {
              inherit base;
              args = {
                modules = let
                  collected = import resolved.paths.configurations (
                    recursiveUpdate base {
                      top = base.names.top or (names.top or "dots");
                      args = normalize configurations;
                    }
                  );
                in {
                  core = collected.imports or [];
                  home = collected."home-manager".sharedModules or [];
                };
              };
            }
          )
      );
  in
    if isAttrs arg && arg ? base && arg ? mods
    then exec arg.base arg.mods
    else mods: exec arg mods;

  mkConfigurations = arg: let
    _name = "config.assembly.mkConfigurations";
    exec = base: args: let
      extraArgs =
        recursiveUpdate (expect {
          name = _name;
          type = "attrs";
          value = base;
          context = "validating base in systems";
        }) (
          optionalAttrs (args != null)
          (expect {
            name = _name;
            type = "attrs";
            value = args;
            context = "validating args type in systems";
          })
        );
      resolved =
        mapAttrs (_: spec: let
          host = recursiveUpdate defaultHost spec;
          class = host.class or defaultHost.class;
          src = mkSrc {
            inherit host;
            overrides = extraArgs;
          };
          specialArgs =
            {
              inherit host src args;
              top = src.names.top or names.top;
            }
            // (removeAttrs src ["lib" "modules" "packages"]);
        in {
          inherit class specialArgs;
          modules =
            (mkMods class)
            ++ (src.modules.core or [])
            ++ (host.imports or [])
            ++ [
              {
                home-manager = {
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = concat {
                    delim = "-";
                    parts = [src.name "backup"];
                  };
                  sharedModules = (mkMods "home") ++ (src.modules.home or []);
                  useGlobalPkgs = true;
                  useUserPackages = true;
                };
              }
            ];
        })
        hosts;
    in
      foldl' recursiveUpdate {} (
        mapAttrsToList (
          class: hostNames: let
            classification = getClassification class;
            builder = getBuilder class;
            opts = ["nixos" "darwin"];
          in
            assert withContext {
              name = _name;
              assertion = elem class opts;
              message = "unknown class '${class}' in host specs, expected one of [${concat {
                delim = ", ";
                parts = opts;
              }}]";
              context = "grouping hosts by class";
            }; {
              ${classification} = genAttrs hostNames (
                name:
                  builder {inherit (resolved.${name}) specialArgs modules;}
              );
            }
        )
        (groupBy (name: resolved.${name}.class) (namesOf resolved))
      );
  in
    if isAttrs arg && arg ? base
    then exec arg.base (arg.args or {})
    else args: exec arg args;
in
  exports
