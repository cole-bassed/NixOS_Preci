{
  api,
  attrsets,
  debug,
  environment,
  filesystem,
  flake,
  lists,
  names,
  paths,
  strings,
  systems,
  types,
  ...
}: let
  exports = {
    scoped = {inherit mkConfiguration mkFlake mkPaths mkSrc;};
    global = {inherit mkFlake mkConfiguration mkSrc;};
  };

  mkFlakeModules = flake.modules.mkFlakeModules or null;
  inherit (attrsets) attrNames filterAttrs genAttrs mapAttrs mapAttrsToList mergeAttrsList optionalAttrs recursiveUpdate;
  inherit (api) hosts;
  inherit (debug) withContext expect;
  inherit (environment) mkSrc;
  inherit (filesystem) mkPaths;
  inherit (lists) elem foldl' groupBy;
  inherit (types) isAttrs isBool isEnabled typeOf;
  inherit (strings) concat;
  inherit (systems) getClassification getBuilder;

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
        paths = mkPaths {
          store = base.paths.store or (base.paths or (paths.store or null));
          local = base.paths.local or (paths.local or null);
        };
      };

      enabled =
        filterAttrs (
          name: value:
            assert withContext {
              inherit name;
              assertion = resolved.paths.store ? ${name};
              message = "'${name}' is not a known path in paths.store. Known paths are [${concat {
                delim = ", ";
                parts = attrNames resolved.paths.store;
              }}]";
              context = "resolving path for '${name}' in assemble";
            };
              (name != "configuration") && (isEnabled value)
        )
        mods;
    in
      mergeAttrsList (
        mapAttrsToList (
          name: args:
            import resolved.paths.store.${name} (base // {args = normalize args;})
        )
        enabled
      )
      // (
        let
          configuration = mods.configuration or false;
        in
          optionalAttrs (isEnabled configuration) (
            mkConfiguration {
              inherit base;
              args = {
                modules = {
                  core = [
                    resolved.paths.store.configuration
                  ];
                  home = [];
                };
              };
            }
          )
      );
  in
    if isAttrs arg && arg ? base && arg ? mods
    then exec arg.base arg.mods
    else mods: exec arg mods;

  mkConfiguration = arg: let
    _name = "config.assembly.mkConfiguration";
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
        mapAttrs (_: host: let
          class = host.class or hosts.default.class;
          src = mkSrc {
            inherit host extraArgs;
            libraries = base.libraries or (args.libraries or null);
          };
          specialArgs =
            {
              inherit host args;
              top = src.name or (src.names.top or (names.top or names.src));
              # ${src.names.lib} = src.${src.names.lib};
              # ${src.names.lib} = removeAttrs src.${src.names.lib} ["flake" "flakes"];
              # inherit src;
              inherit (src) paths;
            }
            // (removeAttrs src ["lib"]);
        in {
          inherit class specialArgs;
          modules =
            (mkFlakeModules class)
            ++ (args.modules.core or [])
            # ++ (host.imports or [])
            # ++ (src.modules.core or [])
            # ++ (extraArgs.modules.core or [])
            # ++ (args.modules.core or [])
            ++ [
              {
                home-manager = {
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = concat {
                    delim = "-";
                    parts = [src.name "backup"];
                  };
                  sharedModules = (mkFlakeModules "home")
                    ++ (args.modules.home or []);
                  # sharedModules =
                  #   (mkFlakeModules "home")
                  #   # ++ (src.modules.home or [])
                  #   ++ (extraArgs.modules.home or []);
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
        (groupBy (name: resolved.${name}.class) (attrNames resolved))
      );
  in
    if isAttrs arg && arg ? base
    then exec arg.base (arg.args or {})
    else args: exec arg args;
in
  exports
